app.cache = {}

(->
  app.cache._db_open = $.Deferred (deferred) ->
    $ ->
      req = webkitIndexedDB.open("cache")
      req.onerror = ->
        deferred.reject()
        app.log("error", "app.cache: db.open失敗")
      req.onsuccess = ->
        deferred.resolve(req.result)

  .pipe (db) ->
    $.Deferred (deferred) ->
      app.log("debug", "cache now v#{db.version or "n/a"}")
      if db.version is "1"
        deferred.resolve(db)
      else
        req = db.setVersion("1")
        window.__req = req #おまじない
        req.onerror = ->
          app.log("error", "app.cache: db.setVersion(1) onerror")
          app.defer -> deferred.reject(db)
        req.onsuccess = ->
          app.log("info", "app.cache: db.setVersion(1) onsuccess")
          db.createObjectStore("cache", keyPath: "url")
          app.defer -> deferred.resolve(db)

  .fail (db) ->
    db and db.close()
    app.critical_error("キャッシュ管理システムの起動に失敗しました")

  .promise()
)()

app.cache.get = (url) ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        objectStore = db.transaction(["cache"]).objectStore("cache")

        req = objectStore.get(url)
        req.onsuccess = () ->
          if typeof req.result is "object"
            deferred.resolve(status: "success", data: req.result)
          else
            deferred.reject(status: "not_found")
        req.onerror = ->
          app.log("error", "app.cache.get: キャッシュの取得に失敗")
          deferred.reject(status: "error")
    , ->
      $.Deferred (deferred) ->
        deferred.reject(status: "error")

    .promise()

app.cache.set = (data) ->
  unless (
    typeof data.url is "string" and
    typeof data.data is "string" and
    typeof data.last_updated is "number" and
    (not data.last_modified? or
      typeof data.last_modified is "number") and
    (not data.etag? or
      typeof data.etag is "string")
  )
    app.log("error", "app.cache.set: 引数が不正です", arguments)
    return $.Deferred().reject().promise()

  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["cache"], webkitIDBTransaction.READ_WRITE)
        transaction.oncomplete = ->
          deferred.resolve(db)
        transaction.onerror = ->
          app.log("error", "app.cache.set: トランザクション中断")
          deferred.reject()

        transaction.objectStore("cache").put(data)

    .promise()

app.cache.remove = (url) ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["cache"], webkitIDBTransaction.READ_WRITE)
        transaction.oncomplete = ->
          deferred.resolve()
        transaction.onerror = ->
          app.log("error", "app.cache.remove: トランザクション中断")
          deferred.reject()

        transaction.objectStore("cache").delete(url)

    .promise()

app.cache.clear = ->
  app.cache._db_open

    .pipe (db) ->
      $.Deferred (deferred) ->
        transaction = db.transaction(["cache"], webkitIDBTransaction.READ_WRITE)
        transaction.objectStore("cache").clear()
        transaction.oncomplete = ->
          deferred.resolve()
        transaction.onerror = ->
          app.log("error", "app.cache.clear: トランザクション中断")
          deferred.reject()

    .promise()
