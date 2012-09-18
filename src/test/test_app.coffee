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

asyncTest "モジュール定義は必ず非同期で行われる", 3, ->
  app.module null, [], ->
    QUnit.step(2)
    return

  app.module "__h", [], ->
    QUnit.step(3)
    start()
    return

  QUnit.step(1)
  return
