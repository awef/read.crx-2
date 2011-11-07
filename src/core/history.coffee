app.history = {}

(->
  app.history._db_open = $.Deferred (deferred) ->
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
      -> deferred.reject()
      -> deferred.resolve(db)
    )
  .promise()
  .fail ->
    app.critical_error("履歴管理システムの起動に失敗しました")
)()

app.history.add = (url, title, date) ->
  if app.assert_arg("app.history.add", ["string", "string", "number"], arguments)
    return $.Deferred().reject().promise()

  app.history._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql(
            "INSERT INTO History values(?, ?, ?)"
            [url, title, date]
          )
        , ->
          app.log("error", "app.history.add: データの格納に失敗しました")
          deferred.reject()
        , ->
          deferred.resolve()

    .promise()

app.history.get = (offset, limit) ->
  offset ?= -1
  limit ?= -1

  if app.assert_arg("app.history.get", ["number", "number"], arguments)
    return $.Deferred().reject().promise()

  app.history._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.readTransaction (transaction) ->
          transaction.executeSql("""
              SELECT * FROM History
                ORDER BY date DESC
                LIMIT ? OFFSET ?
            """
            [limit, offset]
            (transaction, result) ->
              data = []
              key = 0
              length = result.rows.length
              while key < length
                data.push(result.rows.item(key))
                key++
              deferred.resolve(data)
          )
        , ->
          app.log("error", "app.history.get: トランザクション中断")
          deferred.reject()

    .promise()

app.history.get_count = ->
  app.history._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.readTransaction (transaction) ->
          transaction.executeSql("""
              SELECT count() FROM History
            """
            []
            (transaction, result) ->
              deferred.resolve(result.rows.item(0)["count()"])
          )
        , ->
          app.log("error", "app.history.get: トランザクション中断")
          deferred.reject()

    .promise()

app.history.clear = ->
  app.history._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        db.transaction (transaction) ->
          transaction.executeSql("DELETE FROM History")
        , ->
          app.log("error", "app.history.clear: トランザクション中断")
          deferred.reject()
        , ->
          deferred.resolve()

    .promise()
