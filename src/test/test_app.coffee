module "app.deep_copy", {
  setup: ->
    @original =
      test1: 123
      test2: "123"
      test3: [1, 2, 3.14]
      test4:
        test5: 123
        test6: "テスト"
        test7: [
          {test8: Math.PI}
          null
          undefined
          ""
          NaN
          0
          -1.23
        ]
}

test "通常の代入", 2, ->
  original = app.deep_copy(this.original)
  copy = original

  strictEqual(copy, original,
    "シャローコピーはオリジナルと同じオブジェクトを指す")
  copy.test = 321
  deepEqual(copy, original,
    "シャローコピーはただの別名なので、変更も共有される")

test "app.deep_copy", 2, ->
  original = app.deep_copy(this.original)
  copy = app.deep_copy(original)

  notStrictEqual(copy, original,
    "ディープコピーはオリジナルと違うオブジェクト")
  copy.test = 321
  notDeepEqual(copy, original,
    "ディープコピーへの変更はオリジナルに反映されない")

module("app.defer")

asyncTest "渡された関数を非同期で実行する", 2, ->
  app.defer ->
    QUnit.step(2)
    start()

  QUnit.step(1)

module("app.message")

asyncTest "メッセージを送信できる", 1, ->
  app.message.add_listener "__test1", (message) ->
    strictEqual(message, "test", "基本送信テスト")
    start()
  app.message.send("__test1", "test")

asyncTest "リスナがメッセージを編集しても他には反映されない", 2, ->
  app.message.add_listener "__test2", (message) ->
    deepEqual(message, {test: 123})
    message.hoge = 345
  app.message.add_listener "__test2", (message) ->
    deepEqual(message, {test: 123})
    message.hoge = 345
    start()
  app.message.send("__test2", {test: 123})

asyncTest "リスナ中でもリスナを削除出来る", 1, ->
  app.message.add_listener "__test3", listener1 = ->
    ok(true)
    app.message.remove_listener("__test3", listener1)
    app.message.remove_listener("__test3", listener2)
    setTimeout((-> start()), 100)
  app.message.add_listener "__test3", listener2 = -> ok(true)
  app.message.send("__test3", {})

asyncTest "メッセージはparentやiframeにも伝播する", 1, ->
  frame_list = [
    "frame"
    "frame_1"
    "frame_1_1"
    "frame_2"
    "frame_2_1"
    "frame_2_2"
    "frame_2_2_1"
    "frame_2_3"
  ]
  frame_list.sort()

  tmp = []
  app.message.add_listener "message_test_pong", (message) ->
    tmp.push(message.source_id)

  iframe = document.createElement("iframe")
  iframe.src = "message_test.html"
  document.querySelector("#qunit-fixture").appendChild(iframe)

  setTimeout ->
    tmp.sort()
    deepEqual(tmp, frame_list)
    start()
  , 600

module("app.config")

test "文字列を保存/取得できる", ->
  strictEqual(app.config.get("__test"), undefined)
  app.config.set("__test", "12345")
  strictEqual(app.config.get("__test"), "12345")
  app.config.del("__test")
  strictEqual(app.config.get("__test"), undefined)

module("app.safe_href")

test "与えられた文字列がhttp, https以外のURLだった場合、ダミー文字列を返す", 7, ->
  strictEqual(app.safe_href("http://example.com/"), "http://example.com/")
  strictEqual(app.safe_href("https://example.com/"), "https://example.com/")
  strictEqual(app.safe_href(" http://example.com/"), "/view/empty.html")
  strictEqual(app.safe_href(" https://example.com/"), "/view/empty.html")
  strictEqual(app.safe_href(""), "/view/empty.html")
  strictEqual(app.safe_href("javascript:undefined;"), "/view/empty.html")
  strictEqual(app.safe_href("data:text/plain,test"), "/view/empty.html")

module("app.escape_html")

test "与えられた文字列中の<>\"'&をエスケープする", 1, ->
  strictEqual(
    app.escape_html(""" <a href="'#'">test&test&test</a> """),
    """ &lt;a href=&quot;&apos;#&apos;&quot;&gt;test&amp;test&amp;test&lt;/a&gt; """
  )

module("app.module")

asyncTest "非同期にモジュールを定義する事が出来る", 7, ->
  app.module "__a", [], (callback) ->
    QUnit.step(2)
    callback(x: 123)

  app.module "__b", ["__a"], (__a, callback) ->
    QUnit.step(3)
    deepEqual(__a, {x: 123})
    callback({y: 234})

  app.module "__c", ["__b", "__a"], (__b, __a, callback) ->
    QUnit.step(4)
    deepEqual(__a, {x: 123})
    deepEqual(__b, {y: 234})
    callback({})
    start()

  QUnit.step(1)

asyncTest "依存関係が満たされるまで、モジュールの初期化は行われない", 6, ->
  app.module "__d", [], (callback) ->
    QUnit.step(2)
    callback(x: 123)

  app.module "__f", ["__d", "__e"], (__d, __e, callback) ->
    QUnit.step(4)
    deepEqual(__d, {x: 123})
    deepEqual(__e, {y: 234})
    callback({})
    start()

  app.module "__e", [], (callback) ->
    QUnit.step(3)
    callback(y: 234)

  QUnit.step(1)

asyncTest "モジュール名がnullの場合は依存関係の解決のみ行う", 8, ->
  app.module null, ["__g"], (__g) ->
    QUnit.step(3)
    strictEqual(arguments.length, 1)
    deepEqual(__g, {a: "test"})

  app.module null, ["__g"], (__g) ->
    QUnit.step(4)
    strictEqual(arguments.length, 1)
    deepEqual(__g, {a: "test"})
    start()

  app.module "__g", [], (callback) ->
    QUnit.step(2)
    callback(a: "test")

  QUnit.step(1)
