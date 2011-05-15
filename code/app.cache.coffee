`/** @namespace */`
app.cache = {}

app.cache.get = (url) ->
  deferred = $.Deferred()

  req = webkitIndexedDB.open("cache")
  req.onerror = ->
    deferred.reject(status: "error")
    app.log("error", "app.cache.get: indexedDB.openに失敗")
  req.onsuccess = (e) ->
    db = req.result
    if db.version is "1"
      tra = db.transaction(["cache"], webkitIDBTransaction.READ_ONLY)
      tra.oncomplete = (e) ->
        db.close()
      tra.onerror = ->
        db.close()

      objectStore = tra.objectStore("cache")
      req = objectStore.get(url)
      req.onsuccess = (e) ->
        if typeof req.result is "object"
          deferred.resolve(status: "success", data: req.result)
        else
          deferred.reject(status: "not_found")
      req.onerror = ->
        app.log("error", "app.cache.get: キャッシュの取得に失敗")
        deferred.reject(status: "error")
    else
      deferred.reject(status: "error")
      app.log("warn", "app.cache.get: 予期せぬdb.version", db.version)
      db.close()

  deferred.promise()

app.cache.set = (data) ->
  arg = arguments

  $.Deferred (deferred) ->
    if (
      typeof data.url isnt "string" or
      typeof data.data isnt "string" or
      typeof data.last_modified isnt "number" or
      typeof data.last_updated isnt "number"
    )
      app.log("error", "app.cache.set: 引数が不正です", arg)
      deferred.reject()
    else
      deferred.resolve()

  .pipe ->
    $.Deferred (deferred) ->
      req = webkitIndexedDB.open("cache")
      req.onerror = ->
        app.log("error", "app.cache.set: indexedDB.openに失敗")
        deferred.reject()
      req.onsuccess = (e) ->
        deferred.resolve(req.result)

  .pipe (db) ->
    $.Deferred (deferred) ->
      if db.version is "1"
        deferred.resolve(db)
      else
        deferred.reject(db)

  .pipe null, (db) ->
    $.Deferred (deferred) ->
      if db
        req = db.setVersion("1")
        req.onerror = ->
          app.log(
            "error",
            "app.cache.set: db.setVersion失敗(%s -> %s)",
            db.version,
            "1"
          )
          deferred.reject(db)
        req.onsuccess = (e) ->
          db.createObjectStore("cache", {keyPath: "url"})
          app.log(
            "info",
            "app.cache.set: db.setVersion成功(%s -> %s)",
            db.version,
            "1"
          )
          deferred.resolve(db)
      else
        deferred.reject()

  .pipe (db) ->
    $.Deferred (deferred) ->
      transaction = db.transaction(["cache"], webkitIDBTransaction.READ_WRITE)
      transaction.oncomplete = ->
        deferred.resolve(db)
      transaction.onerror = ->
        deferred.reject(db)

      transaction.objectStore("cache").put(data)

  .always (db) ->
    db and db.close()

  .promise()

app.cache.remove = (url) ->
  $.Deferred (deferred) ->
    req = webkitIndexedDB.open("cache")
    req.onerror = -> deferred.reject()
    req.onsuccess = ->
      db = req.result
      if db.version is "1"
        deferred.resolve(db)
      else
        deferred.reject()

  .pipe (db) ->
    $.Deferred (deferred) ->
      transaction = db.transaction(["cache"], webkitIDBTransaction.READ_WRITE)
      transaction.oncomplete = ->
        db.close()
        deferred.resolve()
      transaction.onerror = ->
        db.close()
        deferred.reject()

      transaction.objectStore("cache").delete(url)

  .promise()
