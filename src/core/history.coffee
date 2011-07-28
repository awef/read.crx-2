app.history = {}

(->
  app.history._open_db = $.Deferred (deferred) ->
    req = webkitIndexedDB.open("history")
    req.onerror = ->
      deferred.reject()
      app.log("error", "app.history: db.open失敗")
    req.onsuccess = ->
      deferred.resolve(req.result)

  .pipe (db) ->
    $.Deferred (deferred) ->
      app.log("debug", "history now v#{db.version or "n/a"}")
      if db.version is "1"
        deferred.resolve(db)
      else
        req = db.setVersion("1")
        req.onerror = ->
          app.log("error", "app.history: db.setVersion(1) onerror")
          deferred.reject(db)
        req.onsuccess = ->
          app.log("info", "app.history: db.setVersion(1) onsuccess")
          db.createObjectStore("history", autoIncrement: true)
            .createIndex("date", "date")
          deferred.resolve(db)

  .fail (db) ->
    db and db.close()
    app.critical_error("履歴管理システムの起動に失敗しました")

  .promise()
)()

app.history.add = (url, title, date) ->
  if (
    typeof url isnt "string" or
    typeof title isnt "string" or
    typeof date isnt "number"
  )
    app.log("error", "app.history.add: 引数が不正です", arguments)
    return $.Deferred().reject().promise()

  app.history._open_db

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["history"], webkitIDBTransaction.READ_WRITE)
        transaction.oncomplete = ->
          deferred.resolve()
        transaction.onerror = (e) ->
          app.log("error", "app.history.add: データの格納に失敗しました")
          deferred.reject()

        transaction.objectStore("history").put({url, title, date})

    .promise()

app.history.get = (offset, count) ->
  app.history._open_db

    .pipe (db) ->
      $.Deferred (deferred) ->
        data = []
        data_length = 0

        transaction = db.transaction(["history"])
        object_store = transaction.objectStore("history")

        req_cursor = object_store
          .index("date")
          .openCursor(null, webkitIDBCursor.PREV)
        req_cursor.onsuccess = ->
          cursor = req_cursor.result
          if cursor
            data.push(cursor.value)
            if ++data_length < count
              cursor.continue()
        transaction.onerror = ->
          app.log("error", "app.history.get: トランザクション中断")
          deferred.reject()
        transaction.oncomplete = ->
          deferred.resolve(data)

    .promise()

app.history.clear = ->
  app.history._open_db

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["history"], webkitIDBTransaction.READ_WRITE)
        transaction.objectStore("history").clear()
        transaction.oncomplete = ->
          deferred.resolve()
        transaction.onerror = ->
          app.log("error", "app.history.clear: トランザクション中断")
          deferred.reject()

    .promise()
