module("app.deep_copy")

test "test", 7, ->
  original = test: 123
  copy = original
  strictEqual(copy, original, "シャローコピーはオリジナルとstrictEqual")
  copy.test = 321
  deepEqual(copy, original,
    "シャローコピーはただの別名なので、変更も共有される")

  original = test: 123
  copy = app.deep_copy(original)
  notStrictEqual(copy, original,
    "ディープコピーはオリジナルとstrictEqualにならない")
  deepEqual(copy, original, "ディープコピーはオリジナルと構造は一緒")
  copy.test = 321
  notDeepEqual(copy, original,
    "ディープコピーの編集はオリジナルに影響しない")

  original =
    test1: 123
    test2: "123"
    test3: [1, 2, 3.14]
    test4:
      test5: 123
      test6: "テスト"
      test7: [
        test8: Math.PI
      ]
  copy = app.deep_copy(original)
  notStrictEqual(copy, original,
    "ディープコピーはオリジナルとstrictEqualにならない２")
  deepEqual(copy, original, "ディープコピーはオリジナルと構造は一緒２")

module("app.defer")

asyncTest "test", ->
  x = 123

  app.defer ->
    strictEqual(x, 123)
    x = 321
    strictEqual(x, 321)
    start()

  strictEqual(x, 123)


module("app.message")
asyncTest "test", 1, ->
  app.message.add_listener "__test1", (message) ->
    strictEqual(message, "test", "基本送信テスト")
    start()
  app.message.send("__test1", "test")

asyncTest "test", 2, ->
  app.message.add_listener "__test2", (message) ->
    deepEqual(message, {test: 123}, "メッセージの編集テスト")
    message.hoge = 345
  app.message.add_listener "__test2", (message) ->
    deepEqual(message, {test: 123}, "メッセージの編集テスト")
    message.hoge = 345
    start()
  app.message.send("__test2", test: 123)

module("app.url")

test "app.url.fix", ->
  test_board_url = (fixed_url, service) ->
    strictEqual(app.url.fix(fixed_url), fixed_url, service + " 板URL")
    strictEqual(app.url.fix(fixed_url + "#5"), fixed_url, service + " 板URL")

  test_thread_url = (fixed_url, service) ->
    strictEqual(app.url.fix(fixed_url), fixed_url, service + " スレッドURL")
    strictEqual(app.url.fix(fixed_url[0...-1]), fixed_url, service + " スレッドURL")
    strictEqual(app.url.fix(fixed_url + "l50"), fixed_url, service + " スレッドURL")
    strictEqual(app.url.fix(fixed_url + "50"), fixed_url, service + " スレッドURL")
    strictEqual(app.url.fix(fixed_url + "50/"), fixed_url, service + " スレッドURL")
    strictEqual(app.url.fix(fixed_url + "50-100"), fixed_url, service + " スレッドURL")

  test_pass_url = (url) ->
    strictEqual(app.url.fix(url), url, url)

  test_board_url("http://qb5.2ch.net/operate/", "2ch")
  test_thread_url("http://pc11.2ch.net/test/read.cgi/hp/1277348045/", "2ch")

  test_board_url("http://www.machi.to/tawara/", "まちBBS")
  test_thread_url("http://www.machi.to/bbs/read.cgi/tawara/511234524356/", "まちBBS")

  test_board_url("http://jbbs.livedoor.jp/computer/42710/", "したらば")
  test_thread_url("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/", "したらば")

  test_board_url("http://pele.bbspink.com/erobbs/", "BBSPINK")
  test_thread_url("http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/", "BBSPINK")

  test_board_url("http://ex14.vip2ch.com/part4vip/", "パー速")
  test_thread_url("http://ex14.vip2ch.com/test/read.cgi/part4vip/1291628400/", "パー速")

  test_pass_url("config")
  test_pass_url("bookmark")
  test_pass_url("history")
  test_pass_url("kakikomi_log")

  test_pass_url("http://yuzuru.2ch.net/campus/subback.html")
  test_pass_url("http://info.2ch.net/wiki/")
  test_pass_url("http://info.2ch.net/wiki/index.php?BE%A1%F72ch%B7%C7%BC%A8%C8%C4")

  test_pass_url("http://example.com/")
  test_pass_url("http://www.example.com/")
  test_pass_url("http://example.com/index.html")
  test_pass_url("http://www.example.com/index.html")
  test_pass_url("http://example.com/test/index.html")
  test_pass_url("http://www.example.com/test/index.html")
  test_pass_url("http://example.com/#test")

test "app.url.thread_to_board", ->
  fn = (thread_url, board_url, message) ->
    strictEqual(app.url.thread_to_board(thread_url), board_url, message)

  fn("", "", "空文字列")
  fn("http://qb5.2ch.net/test/read.cgi/operate/1304609594/",
    "http://qb5.2ch.net/operate/", "2ch")
  fn("http://www.machi.to/bbs/read.cgi/tawara/511234524356/",
    "http://www.machi.to/tawara/", "まちBBS")
  fn("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273732874/",
    "http://jbbs.livedoor.jp/computer/42710/", "したらば")
  fn("http://pele.bbspink.com/test/read.cgi/erobbs/9241104701/",
    "http://pele.bbspink.com/erobbs/", "BBSPINK")
  fn("http://bbs.nicovideo.jp/test/read.cgi/bugreport/1297431393/",
    "http://bbs.nicovideo.jp/bugreport/", "ニコニコ動画掲示板")
  fn("http://ex14.vip2ch.com/test/read.cgi/part4vip/1300351822/",
    "http://ex14.vip2ch.com/part4vip/", "パー速VIP")

test "app.url.guess_type", ->
  hoge = (url, expected) ->
    deepEqual(app.url.guess_type(url), expected, url)

  hoge("http://qb5.2ch.net/operate/", type: "board", bbs_type: "2ch")
  hoge("http://pc11.2ch.net/test/read.cgi/hp/1277348045/", type: "thread", bbs_type: "2ch")

  hoge("http://www.machi.to/tawara/", type: "board", bbs_type: "machi")
  hoge("http://www.machi.to/bbs/read.cgi/tawara/511234524356/", type: "thread", bbs_type: "machi")

  hoge("http://jbbs.livedoor.jp/computer/42710/", type: "board", bbs_type: "jbbs")
  hoge("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/", type: "thread", bbs_type: "jbbs")

  hoge("http://pele.bbspink.com/erobbs/", type: "board", bbs_type: "2ch")
  hoge("http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/", type: "thread", bbs_type: "2ch")

  hoge("http://ex14.vip2ch.com/part4vip/", type: "board", bbs_type: "2ch")
  hoge("http://ex14.vip2ch.com/test/read.cgi/part4vip/1291628400/", type: "thread", bbs_type: "2ch")

  hoge("http://example.com/", type: "unknown", bbs_type: "unknown")

  hoge("http://info.2ch.net/wiki/", type: "unknown", bbs_type: "unknown")
  hoge("http://find.2ch.net/test/", type: "unknown", bbs_type: "unknown")
  hoge("http://p2.2ch.net/test/", type: "unknown", bbs_type: "unknown")
  hoge("http://ninja.2ch.net/test/", type: "unknown", bbs_type: "unknown")

test "app.url.sld", ->
  fn = (url, expected) ->
    strictEqual(app.url.sld(url), expected, url)

  fn("", "")
  fn("test", "")
  fn("http:///", "")
  fn("/test.test.test/", "")

  fn("http://example.com/", "example")
  fn("https://example.com/", "example")
  fn("http://www.example.com/", "example")
  fn("https://www.example.com/", "example")

  fn("http://qb5.2ch.net/operate/", "2ch")
  fn("http://qb5.2ch.net/test/read.cgi/operate/1304609594/", "2ch")

  fn("http://www.machi.to/tawara/", "machi")
  fn("http://www.machi.to/bbs/read.cgi/tawara/511234524356/", "machi")

  fn("http://jbbs.livedoor.jp/computer/42710/", "livedoor")
  fn("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/",
    "livedoor")

test "app.url.parse_query", ->
  fn = (url, expected) ->
    deepEqual(app.url.parse_query(url), expected, url)

  fn "https://encrypted.google.com/webhp?hl=ja"
    hl: "ja"

  fn "https://encrypted.google.com/search?hl=ja&qscrl=1&q=%E3%83%86%E3%82%B9%E3%83%88"
    hl: "ja"
    qscrl: "1"
    q: "テスト"

  fn "http://b.hatena.ne.jp/search?q=%E3%83%86%E3%82%B9%E3%83%88"
    q: "テスト"

  fn "http://example.com/?q=%E3%83%86%E3%82%B9%E3%83%88#main"
    q: "テスト"

  fn "http://example.com/?q=%E3%83%86%E3%82%B9%E3%83%88#q=test&page=10"
    q: "テスト"

test "app.url.parse_hashquery", ->
  fn = (url, expected) ->
    deepEqual(app.url.parse_hashquery(url), expected, url)

  fn "https://encrypted.google.com/webhp#hl=ja"
    hl: "ja"

  fn "https://encrypted.google.com/search#hl=ja&qscrl=1&q=%E3%83%86%E3%82%B9%E3%83%88"
    hl: "ja"
    qscrl: "1"
    q: "テスト"

  fn "http://b.hatena.ne.jp/search#q=%E3%83%86%E3%82%B9%E3%83%88"
    q: "テスト"

  fn "http://example.com/?main#q=%E3%83%86%E3%82%B9%E3%83%88"
    q: "テスト"

  fn "http://example.com/?q=test&page=10#q=%E3%83%86%E3%82%B9%E3%83%88"
    q: "テスト"

test "app.url.build_param", ->
  fn = (expected, data) ->
    deepEqual(app.url.build_param(data), expected, JSON.stringify(data))

  fn "hl=ja"
   hl: "ja"

  fn "qscrl=1&q=%E3%83%86%E3%82%B9%E3%83%88"
    qscrl: "1"
    q: "テスト"

  fn "test"
    test: true

  fn "qscrl=1&test&q=%E3%83%86%E3%82%B9%E3%83%88"
    qscrl: "1"
    test: true
    q: "テスト"

test "URLパラメータ系関数整合性テスト", ->
  original_data =
    test: true
    q: "テスト"
    a: "123"
    hoge: "test"

  url = "http://example.com/?" + app.url.build_param(original_data)
  deepEqual(app.url.parse_query(url), original_data)


module "app.config"

test "test", ->
  strictEqual(app.config.get("_test"), undefined)
  app.config.set("_test", "12345")
  strictEqual(app.config.get("_test"), "12345")
  app.config.del("_test")
  strictEqual(app.config.get("_test"), undefined)

