module "app.cache",
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

asyncTest "キャッシュの保存/取得/更新/削除が出来る", ->
  expect(@cache_pattern.length + 1)
  url = @cache_pattern[0].url

  queue = []
  for pattern in @cache_pattern
    ((pattern) ->
      queue.push ->
        $.Deferred (deferred) ->
          app.cache.set(pattern).done ->
            app.cache.get(pattern.url).done (res) ->
              deepEqual(res.data, pattern)
              deferred.resolve()
    )(pattern)

  fn = ->
    if tmp = queue.shift()
      tmp().done ->
        fn()
    else
      app.cache.remove(url).done ->
        app.cache.get(url).fail ->
          ok(true)
          start()
  fn()

asyncTest "期待されない引数が渡された場合、rejectする", ->
  pattern = [
    []
    [""]
    [url: "example"]
    [data: "example"]
    [last_updated: 123]
    [url: "example", data: "example", last_updated: "test"]
    [url: "example", data: 123, last_updated: 123]
    [url: 123, data: "example", last_updated: 123]
    [url: "example", data: "example", last_updated: 123, last_modified: "example"]
    [url: "example", data: "example", last_updated: 123, etag: 123]
    [url: "example", data: "example", last_updated: 123, res_length: "example"]
    [url: "example", data: "example", last_updated: 123, dat_size: "example"]
  ]

  expect(pattern.length)

  next = ->
    if tmp = pattern.splice(0, 1)[0]
      do (tmp) ->
        app.cache.set.apply(null, tmp).fail ->
          ok(true, JSON.stringify(tmp))
          next()
          return
        return
    else
      start()
    return
  next()
  return
