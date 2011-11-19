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

asyncTest "渡された関数を非同期で実行する", 3, ->
  x = 123

  app.defer ->
    strictEqual(x, 123)
    x = 321
    strictEqual(x, 321)
    start()

  strictEqual(x, 123)

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

module("app.config")

test "文字列を保存/取得できる", ->
  strictEqual(app.config.get("__test"), undefined)
  app.config.set("__test", "12345")
  strictEqual(app.config.get("__test"), "12345")
  app.config.del("__test")
  strictEqual(app.config.get("__test"), undefined)
