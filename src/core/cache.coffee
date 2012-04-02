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
      @data = null
      @last_updated = null
      @last_modified = null
      @etag = null
      @res_length = null
      @dat_size = null

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
                    @[key] = if val? then val else null
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
        app.log("error", "Cache::put データが不正です", @)
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

app.cache =
  get: (url) ->
    $.Deferred (d) ->
      app.module null, ["cache"], (Cache) ->
        cache = new Cache(url)
        cache.get()
          .done ->
            keys = [
              "data"
              "last_updated"
              "last_modified"
              "etag"
              "res_length"
              "dat_size"
              "data"
            ]
            tmp = {url}
            for key in keys
              if cache[key]?
                tmp[key] = cache[key]
            d.resolve(status: "success", data: tmp)
            return
          .fail ->
            d.reject(status: "error")
            return
        return
      return
    .promise()

  set: (data = {}) ->
    $.Deferred (d) ->
      app.module null, ["cache"], (Cache) ->
        cache = new Cache(data.url)
        for key, val of data when key isnt "url"
          cache[key] = val
        cache.put().done(d.resolve).fail(d.reject)
        return
      return
    .promise()

  get_count: ->
    $.Deferred (d) ->
      app.module null, ["cache"], (Cache) ->
        (new Cache("*")).count().done(d.resolve).fail(d.reject)
        return
      return
    .promise()

  remove: (url) ->
    $.Deferred (d) ->
      app.module null, ["cache"], (Cache) ->
        (new Cache(url)).delete().done(d.resolve).fail(d.reject)
        return
      return
    .promise()

  clear: ->
    $.Deferred (d) ->
      app.module null, ["cache"], (Cache) ->
        (new Cache("*")).delete().done(d.resolve).fail(d.reject)
        return
      return
    .promise()
