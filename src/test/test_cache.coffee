module "cache",
  setup: ->
    #更新/削除テストのためにすべてURLを同一に
    @cache_pattern = []
    #最小構成
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
    #last_modified
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      last_modified: (new Date("2010-01-01T00:00")).getTime()
    #etag
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      #実際のetagの使用可能文字列を知らないので適当な文字列を入れる
      #どの道テキストが保存可能、以外の確認は不要
      etag: "testtest-test313rttest4wtw4-23425234"
    #res_length
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      res_length: 123
    #dat_size
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      dat_size: 1234
    #last_modified, etag
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      last_modified: (new Date("2010-01-01T00:00")).getTime()
      etag: "testtest-test313rttest4wtw4-23425234"
    #last_modified, etag, res_length
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      last_modified: (new Date("2010-01-01T00:00")).getTime()
      etag: "testtest-test313rttest4wtw4-23425234"
      res_length: 123
    #last_modified, etag, res_length, dat_size
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      last_modified: (new Date("2010-01-01T00:00")).getTime()
      etag: "testtest-test313rttest4wtw4-23425234"
      res_length: 123
      dat_size: 1234
    #last_modified, etag, res_length, dat_size
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "hogehoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      last_modified: (new Date("2010-01-01T00:00")).getTime()
      etag: "testtest-test313rttest4wtw4-23425234"
      res_length: 123
      dat_size: 1234
    #インジェクション系テスト
    @cache_pattern.push
      url: "'; DELETE FROM History --"
      data: "'; DELETE FROM History --"
      last_updated: (new Date("2010-01-01T05:00")).getTime()
      last_modified: (new Date("2010-01-01T00:00")).getTime()
      etag: "'; DELETE FROM History --"
      res_length: 123
      dat_size: 1234
    #\u0000を含むパターン
    @cache_specialcharacter =
      url: "specialcharacter"
      data: "hoge\u0000\u0000hoge"
      last_updated: (new Date("2010-01-01T05:00")).getTime()

asyncTest "キャッシュの保存/取得/更新/削除が出来る", ->
  expect(@cache_pattern.length + 1)

  app.module null, ["jquery", "cache"], ($, Cache) =>
    queue = []
    for pattern in @cache_pattern
      do (pattern) ->
        queue.push ->
          $.Deferred (deferred) ->
            cache = new Cache(pattern.url)
            for key, val of pattern
              cache[key] = val
            cache.put().done ->
              cache = new Cache(pattern.url)
              cache.get().done ->
                is_equal = true
                for key, val of pattern
                  is_equal = is_equal and cache[key] is val
                ok(is_equal)
                deferred.resolve()

    fn = =>
      if tmp = queue.shift()
        tmp().done(fn)
      else
        all = new Cache("*")
        all.count().done (before_count) =>
          cache = new Cache(@cache_pattern[0].url)
          cache.delete().done ->
            cache.get().fail ->
              all.count().done (after_count) ->
                strictEqual(before_count - after_count, 1)
                start()
    fn()

asyncTest "put時、\\u0000を\\u0020に置換する", 1, ->
  app.module null, ["jquery", "cache"], ($, Cache) =>
    pattern = @cache_specialcharacter

    cache = new Cache(pattern.url)
    for key, val of pattern
      cache[key] = val
    cache.put().done ->
      cache = new Cache(pattern.url)

      cache.get().done ->
        strictEqual(cache.data, "hoge\u0020\u0020hoge")
        cache.delete().done ->
          start()
  return

asyncTest "設定されていない項目にアクセスした場合、nullを返す", 10, ->
  app.module null, ["jquery", "cache"], ($, Cache) =>
    cache = new Cache("__test")
    strictEqual(cache.data, null)
    strictEqual(cache.last_updated, null)
    strictEqual(cache.last_modified, null)
    strictEqual(cache.etag, null)
    strictEqual(cache.res_length, null)
    strictEqual(cache.dat_size, null)
    cache.data = "test"
    cache.last_updated = Date.now()

    cache.put().done ->
      cache = new Cache("__test")
      cache.get().done ->
        strictEqual(cache.last_modified, null)
        strictEqual(cache.etag, null)
        strictEqual(cache.res_length, null)
        strictEqual(cache.dat_size, null)
        cache.delete().done(start)
        return
      return
    return
  return

asyncTest "期待されない値がputされた場合、rejectする", ->
  pattern = [
    {}
    {url: "example"}
    {data: "example"}
    {last_updated: 123}
    {url: "example", data: "example", last_updated: "test"}
    {url: "example", data: 123, last_updated: 123}
    {url: 123, data: "example", last_updated: 123}
    {url: "example", data: "example", last_updated: 123, last_modified: "example"}
    {url: "example", data: "example", last_updated: 123, etag: 123}
    {url: "example", data: "example", last_updated: 123, res_length: "example"}
    {url: "example", data: "example", last_updated: 123, dat_size: "example"}
  ]
  expect(pattern.length)

  app.module null, ["cache"], (Cache) ->
    for tmp in pattern
      cache = new Cache(tmp.url)
      for key, val in tmp
        if key isnt "url"
          cache[key] = val
      cache.put().fail -> ok(true)
    start()
