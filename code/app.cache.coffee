`/** @namespace */`
app.cache = {}

app.cache.get = (url, callback) ->
  deferred = $.Deferred()

  deferred.always (res) ->
    if callback
      callback(res)

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
  deferred

app.cache.set = (data) ->
  if (
    typeof data.url isnt "string" or
    typeof data.data isnt "string" or
    typeof data.last_modified isnt "number" or
    typeof data.last_updated isnt "number"
  )
    app.log("error", "app.cache.set: 引数が不正です", arguments)
    return

  db = null

  idb_setversion = ->
    req = db.setVersion("1")
    req.onerror = ->
      app.log(
        "error",
        "app.cache.set: db.setVersion失敗(%s -> %s)",
        db.version,
        "1"
      )
      db.close()
    req.onsuccess = (e) ->
      db.createObjectStore("cache", {keyPath: "url"})
      app.log(
        "info",
        "app.cache.set: db.setVersion成功(%s -> %s)",
        db.version,
        "1"
      )
      idb_putdata()
  idb_putdata = ->
    tra = db.transaction(["cache"], webkitIDBTransaction.READ_WRITE)
    tra.oncomplete = ->
      db.close()
    tra.onerror = ->
      db.close()

    objectStore = tra.objectStore("cache")
    req = objectStore.put(data)

  req = webkitIndexedDB.open("cache")
  req.onerror = ->
    app.log("error", "app.cache.set: indexedDB.openに失敗")
  req.onsuccess = (e) ->
    db = req.result

    if db.version isnt "1"
      idb_setversion()
    else
      idb_putdata()
