app.read_state = {}

(->
  app.read_state._db_open = $.Deferred (deferred) ->
    req = webkitIndexedDB.open("read_state")
    req.onerror = ->
      deferred.reject()
      app.log("error", "app.read_state: db.open失敗")
    req.onsuccess = ->
      deferred.resolve(req.result)

  .pipe (db) ->
    $.Deferred (deferred) ->
      if db.version is "1"
        deferred.resolve(db)
      else
        req = db.setVersion("1")
        req.onerror = ->
          app.log("error", "app.read_state: db.setVersion失敗(#{db.version} -> 1)")
          deferred.reject(db)
        req.onsuccess = () ->
          db.createObjectStore("read_state", keyPath: "url")
            .createIndex("board_url", "board_url")
          app.log("info", "app.read_state: db.setVersion成功(#{db.version} -> 1)")
          deferred.resolve(db)

  .fail (db) -> db and db.close()

  .promise()
)()

app.read_state.get = (url) ->
  url = app.url.fix(url)

  app.read_state._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["read_state"])
        objectStore = transaction.objectStore("read_state")

        req = objectStore.get(url)
        req.onsuccess = ->
          if typeof req.result is "object"
            read_state = req.result
            delete read_state.board_url
            deferred.resolve(read_state)
          else
            deferred.resolve()
        req.onerror = ->
          deferred.reject()

    .promise()

app.read_state.get_by_board = (board_url) ->
  app.read_state._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        data = []

        transaction = db.transaction(["read_state"])
        transaction.onerror = ->
          app.log("error", "app.read_state.get_by_board:
 トランザクション中断")
          deferred.reject()
        transaction.oncomplete = ->
          deferred.resolve(data)

        object_store = transaction.objectStore("read_state")
        req = object_store
          .index("board_url")
          .openCursor(webkitIDBKeyRange.only(board_url))
        req.onsuccess = ->
          cursor = req.result
          if cursor
            read_state = cursor.value
            delete read_state.board_url
            data.push(read_state)
            cursor.continue()

    .promise()

app.read_state.set = (read_state) ->
  if (
    typeof read_state.url isnt "string" or
    typeof read_state.last isnt "number" or
    typeof read_state.read isnt "number" or
    typeof read_state.received isnt "number"
  )
    app.log("error", "app.read_state.set: 引数が不正です", arguments)
    return $.Deferred().reject().promise()

  read_state.url = app.url.fix(read_state.url)
  read_state.board_url = app.url.thread_to_board(read_state.url)

  app.read_state._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["read_state"], webkitIDBTransaction.READ_WRITE)
        transaction.onerror = ->
          app.log("error", "app.read_state.set: 保存失敗")
          deferred.reject()
        transaction.oncomplete = ->
          deferred.resolve()
        transaction.objectStore("read_state").put(read_state)

    .always ->
      delete read_state.board_url
      app.bookmark.update_read_state(read_state)

    .promise()

app.read_state.remove = (url) ->
  app.read_state._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["read_state"], webkitIDBTransaction.READ_WRITE)
        transaction.onerror = ->
          app.log("error", "app.read_state.remove: 削除失敗")
          deferred.reject()
        transaction.oncomplete = ->
          deferred.resolve()
        transaction.objectStore("read_state").delete(url)

    .promise()

