module("app.url")

test "URLパラメータ系の関数は互換性を持つ", 1, ->
  original_data =
    test: true
    q: "テスト"
    a: "123"
    hoge: "test"
  url = "http://example.com/?" + app.url.build_param(original_data)
  deepEqual(app.url.parse_query(url), original_data)

module "app.url.fix",
  setup: ->
    @fixed_board_url = [
      "http://qb5.2ch.net/operate/"
      "http://www.machi.to/tawara/"
      "http://jbbs.livedoor.jp/computer/42710/"
      "http://pele.bbspink.com/erobbs/"
      "http://ex14.vip2ch.com/part4vip/"
    ]
    @fixed_thread_url = [
      "http://pc11.2ch.net/test/read.cgi/hp/1277348045/"
      "http://www.machi.to/bbs/read.cgi/tawara/511234524356/"
      "http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/"
      "http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/"
      "http://ex14.vip2ch.com/test/read.cgi/part4vip/1291628400/"
    ]
    @special_url = [
      "bookmark"
      "bookmark_source_selector"
      "config"
      "history"
      "inputurl"
    ]
    @other_url = [
      "http://example.com/"
      "http://example.com/#test"
      "http://example.com/index.html"
      "http://example.com/test/index.html"
      "http://info.2ch.net/wiki/index.php?BE%A1%F72ch%B7%C7%BC%A8%C8%C4"
      "http://www.example.com/"
      "http://www.example.com/index.html"
      "http://www.example.com/test/index.html"
      "http://yuzuru.2ch.net/campus/subback.html"
    ]

test "既に整っているURLは変更しない", ->
  tmp = [].concat(@special_url, @fixed_board_url, @fixed_thread_url)
  expect(tmp.length)
  tmp.forEach (url) ->
    strictEqual(app.url.fix(url), url)

test "明確にスレでも板でも無いURL形式は無視する", ->
  expect(@other_url.length)
  @other_url.forEach (url) ->
    strictEqual(app.url.fix(url), url)

test "板URLの#以降を削除する", ->
  expect(@fixed_board_url.length)
  @fixed_board_url.forEach (url) ->
    strictEqual(app.url.fix(url + "#5"), url)

test "スレURL末尾の/を補完する", ->
  expect(@fixed_thread_url.length)
  @fixed_thread_url.forEach (url) ->
    strictEqual(app.url.fix(url.slice(0, -1)), url)

test "スレURLのURLオプションを削除する", ->
  expect(@fixed_thread_url.length * 5)
  @fixed_thread_url.forEach (url) ->
    strictEqual(app.url.fix(url + "l50"), url)
    strictEqual(app.url.fix(url + "50"), url)
    strictEqual(app.url.fix(url + "50/"), url)
    strictEqual(app.url.fix(url + "50-100"), url)
    strictEqual(app.url.fix(url + "50-100/"), url)

module("app.url.guess_type")

test "URLを解析して、その情報を返す", 15, ->
  test = (url, expected) ->
    deepEqual(app.url.guess_type(url), expected)
  test("http://qb5.2ch.net/operate/",
    {type: "board", bbs_type: "2ch"})
  test("http://pc11.2ch.net/test/read.cgi/hp/1277348045/",
    {type: "thread", bbs_type: "2ch"})
  test("http://www.machi.to/tawara/",
    {type: "board", bbs_type: "machi"})
  test("http://www.machi.to/bbs/read.cgi/tawara/511234524356/",
    {type: "thread", bbs_type: "machi"})
  test("http://jbbs.livedoor.jp/computer/42710/",
    {type: "board", bbs_type: "jbbs"})
  test("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/",
    {type: "thread", bbs_type: "jbbs"})
  test("http://pele.bbspink.com/erobbs/",
    {type: "board", bbs_type: "2ch"})
  test("http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/",
    {type: "thread", bbs_type: "2ch"})
  test("http://ex14.vip2ch.com/part4vip/",
    {type: "board", bbs_type: "2ch"})
  test("http://ex14.vip2ch.com/test/read.cgi/part4vip/1291628400/",
    {type: "thread", bbs_type: "2ch"})
  test("http://example.com/",
    {type: "unknown", bbs_type: "unknown"})
  test("http://info.2ch.net/wiki/",
    {type: "unknown", bbs_type: "unknown"})
  test("http://find.2ch.net/test/",
    {type: "unknown", bbs_type: "unknown"})
  test("http://p2.2ch.net/test/",
    {type: "unknown", bbs_type: "unknown"})
  test("http://ninja.2ch.net/test/",
    {type: "unknown", bbs_type: "unknown"})

module "app.url.tsld",
  setup: ->
    @test = (url, expected) ->
      strictEqual(app.url.tsld(url), expected)

test "URLのトップ及びサブレベルドメインを返す", 10, ->
  @test("http://example.com/", "example.com")
  @test("https://example.com/", "example.com")
  @test("http://www.example.com/", "example.com")
  @test("https://www.example.com/", "example.com")
  @test("http://qb5.2ch.net/operate/", "2ch.net")
  @test("http://qb5.2ch.net/test/read.cgi/operate/1304609594/", "2ch.net")
  @test("http://www.machi.to/tawara/", "machi.to")
  @test("http://www.machi.to/bbs/read.cgi/tawara/511234524356/", "machi.to")
  @test("http://jbbs.livedoor.jp/computer/42710/", "livedoor.jp")
  @test("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/",
    "livedoor.jp")

test "該当する物が無い時は空文字列を返す", 4, ->
  @test("", "")
  @test("test", "")
  @test("http:///", "")
  @test("/test.test.test/", "")

module("app.url.parse_query")

test "URLを渡すと、location.searchをパースして返す", 5, ->
  [
    ["https://encrypted.google.com/webhp?hl=ja",
      {hl: "ja"}]
    ["https://encrypted.google.com/search?hl=ja&qscrl=1&q=%E3%83%86%E3%82%B9%E3%83%88",
      {hl: "ja", qscrl: "1", q: "テスト"}]
    ["http://b.hatena.ne.jp/search?q=%E3%83%86%E3%82%B9%E3%83%88",
      {q: "テスト"}]
    ["http://example.com/?q=%E3%83%86%E3%82%B9%E3%83%88#main",
      {q: "テスト"}]
    ["http://example.com/?q=%E3%83%86%E3%82%B9%E3%83%88#q=test&page=10",
      {q: "テスト"}]
  ].forEach (rule) ->
    deepEqual(app.url.parse_query(rule[0]), rule[1])

module("app.url.parse_hashquery")

test "URLを渡すと、location.hashをパースして返す", 5, ->
  [
    ["https://encrypted.google.com/webhp#hl=ja",
      {hl: "ja"}]
    ["https://encrypted.google.com/search#hl=ja&qscrl=1&q=%E3%83%86%E3%82%B9%E3%83%88",
      {hl: "ja", qscrl: "1", q: "テスト"}]
    ["http://b.hatena.ne.jp/search#q=%E3%83%86%E3%82%B9%E3%83%88",
      {q: "テスト"}]
    ["http://example.com/?main#q=%E3%83%86%E3%82%B9%E3%83%88",
      {q: "テスト"}]
    ["http://example.com/?q=test&page=10#q=%E3%83%86%E3%82%B9%E3%83%88",
      {q: "テスト"}]
  ].forEach (rule) ->
    deepEqual(app.url.parse_hashquery(rule[0]), rule[1])

module("app.url.build_param")

test "オブジェクトをURLパラメータとして使用できる文字列に変換する", 4, ->
  [
    [{hl: "ja"}, "hl=ja"],
    [{qscrl: "1", q: "テスト"}, "qscrl=1&q=%E3%83%86%E3%82%B9%E3%83%88"],
    [{test: true}, "test"],
    [{qscrl: "1", test: true, q: "テスト"}, "qscrl=1&test&q=%E3%83%86%E3%82%B9%E3%83%88"]
  ].forEach (rule) ->
    strictEqual(app.url.build_param(rule[0]), rule[1])

