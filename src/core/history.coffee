app.module "history", [], (callback) ->
  ###*
  @class History
  @static
  ###
  class History
    @_db_open: ->
      unless @_db_open_promise?
        @_db_open_promise = $.Deferred((d) ->
          db = openDatabase("History", "", "History", 0)
          db.transaction(
            (transaction) ->
              transaction.executeSql """
                CREATE TABLE IF NOT EXISTS History(
                  url TEXT NOT NULL,
                  title TEXT NOT NULL,
                  date INTEGER NOT NULL
                )
              """
              return
            -> d.reject(); return
            -> d.resolve(db); return
          )
        ).promise()
      @_db_open_promise

    ###*
    @method add
    @param {String} url
    @param {String} title
    @param {Number} date
    @return {Promise}
    ###
    @add: (url, title, date) ->
      if app.assert_arg("History.add", ["string", "string", "number"], arguments)
        return $.Deferred().reject().promise()

      @_db_open().pipe((db) -> $.Deferred (d) ->
        db.transaction(
          (transaction) ->
            transaction.executeSql(
              "INSERT INTO History values(?, ?, ?)"
              [url, title, date]
            )
            return
          ->
            app.log("error", "History.add: データの格納に失敗しました")
            d.reject()
            return
          -> d.resolve(); return
        )
        return
      )
      .promise()

    ###*
    @method get
    @param {Number} offset
    @param {Number} limit
    @return {Promise}
    ###
    @get: (offset = -1, limit = -1) ->
      if app.assert_arg("History.get", ["number", "number"], arguments)
        return $.Deferred().reject().promise()

      @_db_open().pipe((db) -> $.Deferred (d) ->
        db.readTransaction(
          (transaction) ->
            transaction.executeSql(
              "SELECT * FROM History ORDER BY date DESC LIMIT ? OFFSET ?"
              [limit, offset]
              (transaction, result) ->
                data = []
                key = 0
                length = result.rows.length
                while key < length
                  data.push(result.rows.item(key))
                  key++
                d.resolve(data)
                return
            )
            return
          ->
            app.log("error", "History.get: トランザクション中断")
            d.reject()
            return
        )
      )
      .promise()

    ###*
    @method count
    @return {Promise}
    ###
    @count: ->
      @_db_open().pipe((db) -> $.Deferred (d) ->
        db.readTransaction(
          (transaction) ->
            transaction.executeSql(
              "SELECT count() FROM History"
              []
              (transaction, result) ->
                d.resolve(result.rows.item(0)["count()"])
                return
            )
            return
          ->
            app.log("error", "History.count: トランザクション中断")
            d.reject()
            return
        )
      )
      .promise()

    ###*
    @method clear
    @param {Number} offset
    @return {Promise}
    ###
    @clear = (offset) ->
      @_db_open().pipe((db) -> $.Deferred (d) ->
        db.transaction(
          (transaction) ->
            if typeof offset is "number"
              transaction.executeSql("DELETE FROM History WHERE rowid < (SELECT rowid FROM History ORDER BY date DESC LIMIT 1 OFFSET ?)", [offset - 1])
            else
              transaction.executeSql("DELETE FROM History")
            return
          ->
            app.log("error", "app.history.clear: トランザクション中断")
            d.reject()
            return
          ->
            d.resolve()
            return
        )
        return
      )
      .promise()

  callback(History)
  return

app.history = {}

app.history.add = (url, title, date) ->
  if app.assert_arg("History.add", ["string", "string", "number"], arguments)
    return $.Deferred().reject().promise()

  $.Deferred((d) ->
    app.module null, ["history"], (History) ->
      History.add(url, title, date)
        .done(-> d.resolve(); return)
        .fail(-> d.reject(); return)
      return
  )
  .promise()

app.history.get = (offset = -1, limit = -1) ->
  if app.assert_arg("History.get", ["number", "number"], arguments)
    return $.Deferred().reject().promise()

  $.Deferred((d) ->
    app.module null, ["history"], (History) ->
      History.get(offset, limit)
        .done((a) -> d.resolve(a); return)
        .fail(-> d.reject(); return)
      return
  )
  .promise()

app.history.get_count = ->
  $.Deferred((d) ->
    app.module null, ["history"], (History) ->
      History.count()
        .done((a) -> d.resolve(a); return)
        .fail(-> d.reject(); return)
      return
  )
  .promise()

app.history.clear = (offset) ->
  $.Deferred((d) ->
    app.module null, ["history"], (History) ->
      History.clear(offset)
        .done(-> d.resolve(); return)
        .fail(-> d.reject(); return)
      return
  )
  .promise()
