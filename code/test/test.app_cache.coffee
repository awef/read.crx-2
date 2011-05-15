module("app.cache")

asyncTest "test", ->
  original_cache =
    url: "__test"
    data: "hogehoge"
    last_modified: (new Date("2010-01-01T00:00")).getTime()
    last_updated: (new Date("2010-01-01T05:00")).getTime()

  app.cache.set(original_cache)
    .pipe ->
      ok(true, "app.cache.set done")
      app.cache.get(original_cache.url)
    , ->
      ok(false, "app.cache.set fail")

    .pipe (res) ->
      ok(true, "app.cache.get done")
      deepEqual(res.data, original_cache, "キャッシュ内容チェック")
      app.cache.remove(original_cache.url)
    , ->
      ok(false, "app.cache.get fail")

    .pipe ->
      ok(true, "app.cache.remove done")
      app.cache.get(original_cache.url)
    , ->
      ok(false, "app.cache.remove fail")

    .pipe ->
      ok(false, "app.cache.get done")
    , ->
      ok(true, "app.cache.get fail")

    .always ->
      start()
