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

module "app.config"

test "test", ->
  strictEqual(app.config.get("_test"), undefined)
  app.config.set("_test", "12345")
  strictEqual(app.config.get("_test"), "12345")
  app.config.del("_test")
  strictEqual(app.config.get("_test"), undefined)

