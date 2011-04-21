app.history = {}

app.history.add = (url, title) ->
  db = null

  if typeof url isnt "string" or typeof title isnt "string"
    app.log("error", "app.history.add: 引数が不正です", arguments)
    return
  idb_transaction = ->
    transaction = db.transaction(["history"],
      webkitIDBTransaction.READ_WRITE)
    transaction.oncomplete = ->
      db.close()
    transaction.onerror = (e) ->
      db.close()
      app.log("error", "app.history.add: データの格納に失敗しました")

    transaction
      .objectStore("history")
      .put({url, title, date: Date.now()})

  req_open = webkitIndexedDB.open("history")
  req_open.onerror = ->
    app.log("error", "app.history.add: データベースへの接続に失敗")
  req_open.onsuccess = ->
    db = req_open.result

    if db.version is "1"
      idb_transaction()
    else
      req_setversion = db.setVersion("1")
      req_setversion.onerror = ->
        app.log("error", "app.history.add: db.setVersion失敗(%s -> %s)",
          db.version, "1")
      req_setversion.onsuccess = ->
        db.createObjectStore("history", {autoIncrement: true})
          .createIndex("date", "date")

        app.log("info", "app.history.add: db.setVersion成功(%s -> %s)",
          db.version, "1")
        idb_transaction()

app.history.get = (offset, count, callback) ->
  req_open = webkitIndexedDB.open("history")
  req_open.onerror = ->
    callback(status: "error")
    app.log("error", "app.history.get: データベースへの接続に失敗")
  req_open.onsuccess = ->
    db = req_open.result
    data = []

    if db.version is "1"
      transaction = db.transaction(["history"],
        webkitIDBTransaction.READ_ONLY)
      object_store = transaction.objectStore("history")
      req_cursor = object_store
        .index("date")
        .openCursor(null, webkitIDBCursor.PREV)
      req_cursor.onsuccess = ->
        cursor = req_cursor.result
        if cursor
          data.push(cursor.value)
          cursor.continue()
      transaction.onerror = ->
        db.close()
        app.log("error", "app.history.get: トランザクション中断")
        callback(status: "error")
      transaction.oncomplete = ->
        db.close()
        callback(status: "success", data: data)
    else
      db.close()
      app.log("warn", "app.history.get: 非対応のdb.version %s", db.version)
