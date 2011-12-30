app.cache = {}

do ->
  app.cache._db_open = $.Deferred (deferred) ->
    db = openDatabase("Cache", "", "Cache", 0)
    db.transaction(
      (transaction) ->
        transaction.executeSql """
          CREATE TABLE IF NOT EXISTS Cache(
            url TEXT NOT NULL PRIMARY KEY,
            data TEXT NOT NULL,
            last_updated INTEGER NOT NULL,
            last_modified INTEGER,
            etag TEXT,
            res_length INTEGER,
            dat_size INTEGER
          )
        """
      -> deferred.reject()
      -> deferred.resolve(db)
    )
  .promise()
  .fail ->
    app.critical_error("キャッシュ管理システムの起動に失敗しました")

app.cache.set = (data) ->
  unless typeof data is "object" and
      typeof data.url is "string" and
      typeof data.data is "string" and
      typeof data.last_updated is "number" and
      (not data.last_modified? or
        typeof data.last_modified is "number") and
      (not data.etag? or
        typeof data.etag is "string") and
      (not data.res_length? or
        (typeof data.res_length is "number" and not isNaN(data.res_length))) and
      (not data.dat_size? or
        (typeof data.dat_size is "number" and not isNaN(data.dat_size)))
    app.log("error", "app.cache.set: 引数が不正です", arguments)
    return $.Deferred().reject().promise()

  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql(
            "INSERT OR REPLACE INTO Cache values(?, ?, ?, ?, ?, ?, ?)"
            [
              data.url
              data.data
              data.last_updated
              data.last_modified or null
              data.etag or null
              data.res_length or null
              data.dat_size or null
            ]
          )
        , ->
          app.log("error", "app.cache.set: トランザクション失敗")
          deferred.reject()
        , ->
          deferred.resolve()

    .promise()

app.cache.get = (url) ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql("""
              SELECT * FROM Cache
                WHERE url = ?
            """
            [url]
            (transaction, result) ->
              if result.rows.length is 1
                data = app.deep_copy(result.rows.item(0))
                for key of data
                  delete data[key] unless data[key]?
                deferred.resolve({status: "success", data})
              else
                deferred.reject(status: "not_found")
          )
        , ->
          app.log("error", "app.cache.get: トランザクション中断")
          deferred.reject(status: "error")

    .promise()

app.cache.remove = (url) ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql("""
            DELETE FROM Cache
              WHERE url = ?
          """, [url])
        , ->
          app.log("error", "app.cache.remove: トランザクション中断")
          deferred.reject()
        , ->
          deferred.resolve()

    .promise()

app.cache.get_count = ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql("""
              SELECT count() FROM Cache
            """
            []
            (transaction, result) ->
              deferred.resolve(result.rows.item(0)["count()"])
          )
        , ->
          app.log("error", "app.cache.get_count: トランザクション中断")
          deferred.reject(status: "error")

    .promise()

app.cache.clear = ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql("DELETE FROM Cache")
        , ->
          app.log("error", "app.cache.clear: トランザクション中断")
          deferred.reject()
        , ->
          deferred.resolve()

    .promise()

app.module "cache", ["jquery"], ($, callback) ->
  db = null
  db_open = $.Deferred (deferred) ->
    db = openDatabase("Cache", "", "Cache", 0)
    db.transaction(
      (tr) ->
        tr.executeSql """
          CREATE TABLE IF NOT EXISTS Cache(
            url TEXT NOT NULL PRIMARY KEY,
            data TEXT NOT NULL,
            last_updated INTEGER NOT NULL,
            last_modified INTEGER,
            etag TEXT,
            res_length INTEGER,
            dat_size INTEGER
          )
        """
      -> deferred.reject()
      -> deferred.resolve(db)
    )

  class Cache
    constructor: (@key) ->

    get: ->
      $.Deferred (deferred) =>
        db.transaction(
          (tr) =>
            tr.executeSql(
              "SELECT * FROM Cache WHERE url = ?"
              [@key]
              (tr, result) =>
                if result.rows.length is 1
                  data = app.deep_copy(result.rows.item(0))
                  for key, val of data
                    if val?
                      @[key] = val
                  deferred.resolve()
                else
                  deferred.reject()
            )
          ->
            app.log("error", "Cache::get トランザクション中断")
            deferred.reject()
        )
      .promise()

    count: ->
      unless @key is "*"
        app.log("error", "Cache::count 未実装")
        return $.Deferred().reject().promise()

      $.Deferred (deferred) ->
        db.transaction(
          (tr) ->
            tr.executeSql(
              "SELECT count() FROM Cache"
              []
              (tr, result) ->
                deferred.resolve(result.rows.item(0)["count()"])
            )
          ->
            app.log("error", "Cache::count トランザクション中断")
            deferred.reject()
        )
      .promise()

    put: ->
      unless typeof @key is "string" and
          typeof @data is "string" and
          typeof @last_updated is "number" and
          (not @last_modified? or typeof @last_modified is "number") and
          (not @etag? or typeof @etag is "string") and
          (not @res_length? or (typeof @res_length is "number" and not isNaN(@res_length))) and
          (not @dat_size? or (typeof @dat_size is "number" and not isNaN(@dat_size)))
        app.log("error", "Cache::set データが不正です", @)
        return $.Deferred().reject().promise()

      $.Deferred (deferred) =>
        db.transaction(
          (tr) =>
            tr.executeSql(
              "INSERT OR REPLACE INTO Cache values(?, ?, ?, ?, ?, ?, ?)"
              [
                @key
                @data
                @last_updated
                @last_modified or null
                @etag or null
                @res_length or null
                @dat_size or null
              ]
            )
          ->
            app.log("error", "Cache::put トランザクション失敗")
            deferred.reject()
          ->
            deferred.resolve()
        )
      .promise()

    delete: ->
      $.Deferred (deferred) =>
        db.transaction(
          (tr) =>
            if @key is "*"
              tr.executeSql("DELETE FROM Cache")
            else
              tr.executeSql("DELETE FROM Cache WHERE url = ?", [@key])
          ->
            app.log("error", "Cache::delete: トランザクション中断")
            deferred.reject()
          ->
            deferred.resolve()
        )
      .promise()

  db_open
    .done ->
      callback(Cache)
    .fail ->
      app.critical_error("キャッシュ管理システムの起動に失敗しました")
