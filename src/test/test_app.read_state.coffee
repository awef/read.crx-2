module "app.read_state",
  setup: ->
    @one = (type, listener) ->
      wrapper = ->
        listener.apply(@, arguments)
        app.message.remove_listener(type, wrapper)
      app.message.add_listener(type, wrapper)

asyncTest "read_stateの保存/更新/取得/削除が出来る", 23, ->
  original_read_state_1 =
    url: "http://dummyserver.2ch.net/test/read.cgi/dummyboard/1234/"
    last: 123
    read: 234
    received: 345
  read_state_1 = app.deep_copy(original_read_state_1)

  $.when(true).pipe =>
    promise_message = (
      $.Deferred (deferred) =>
        @one "read_state_updated", (message) ->
          ok(true, "メッセージ到達")
          deepEqual(message, {
            board_url: app.url.thread_to_board(original_read_state_1.url)
            read_state: original_read_state_1
          }, "メッセージのチェック")
          deferred.resolve()
      .promise()
    )
    promise_set = app.read_state.set(read_state_1)
    deepEqual(read_state_1, original_read_state_1, "set: 引数の汚染チェック")
    $.when(promise_set, promise_message)
  .pipe ->
    ok(true, "set, message: 成功")
    app.read_state.get(original_read_state_1.url)
  .pipe (res) ->
    ok(true, "get: 成功")
    deepEqual(res, original_read_state_1, "get: 取得結果の確認")
    app.read_state.get_by_board(app.url.thread_to_board(original_read_state_1.url))
  .pipe (res) ->
    ok(true, "get_by_board: 成功")
    deepEqual(res, [original_read_state_1], "get_by_board: 取得結果の確認")
  .pipe =>
    original_read_state_1.last += 5
    original_read_state_1.read += 10
    original_read_state_1.received += 15
    read_state_1 = app.deep_copy(original_read_state_1)
    promise_message = (
      $.Deferred (deferred) =>
        @one "read_state_updated", (message) ->
          ok(true, "メッセージ到達")
          deepEqual(message, {
            board_url: app.url.thread_to_board(original_read_state_1.url)
            read_state: original_read_state_1
          }, "メッセージのチェック")
          deferred.resolve()
      .promise()
    )
    promise_set = app.read_state.set(read_state_1)
    deepEqual(read_state_1, original_read_state_1, "set: 引数の汚染チェック")
    $.when(promise_set, promise_message)
  .pipe ->
    ok(true, "set, message: 更新成功")
    app.read_state.get(original_read_state_1.url)
  .pipe (res) ->
    ok(true, "get: 成功")
    deepEqual(res, original_read_state_1, "get: 取得結果の確認")
    app.read_state.get_by_board(app.url.thread_to_board(original_read_state_1.url))
  .pipe (res) =>
    ok(true, "get_by_board: 成功")
    deepEqual(res, [original_read_state_1], "get_by_board: 取得結果の確認")

    removePromise = app.read_state.remove(original_read_state_1.url)

    messagePromise = (
      $.Deferred (deferred) =>
        @one "read_state_removed", (message) ->
          ok(true, "メッセージ到達")
          deepEqual(message, {
            url: original_read_state_1.url
          }, "メッセージのチェック")
          deferred.resolve()
      .promise()
    )

    $.when(removePromise, messagePromise)

  .pipe ->
    ok(true, "remove: 成功")
    app.read_state.get(original_read_state_1.url)
  .pipe null, (res) ->
    ok(true, "get: 成功")
    deepEqual(res, undefined, "get: 削除確認")
    app.read_state.get_by_board(app.url.thread_to_board(original_read_state_1.url))
  .pipe (res) ->
    ok(true, "get_by_board: 成功")
    deepEqual(res, [], "get_by_board: 削除確認")
    start()

asyncTest "read_stateを板URLから取得出来る", 4, ->
  read_state_1 =
    url: "http://dummyserver.2ch.net/test/read.cgi/dummyboard/1234/"
    last: 123
    read: 234
    received: 345

  read_state_2 =
    url: "http://dummyserver.2ch.net/test/read.cgi/dummyboard/2345/"
    last: 143
    read: 254
    received: 365

  read_state_3 =
    url: "http://dummyserver.2ch.net/test/read.cgi/dummyboard/12421/"
    last: 9999
    read: 9999
    received: 9999

  $.when(
    app.read_state.set(read_state_1)
    app.read_state.set(read_state_2)
    app.read_state.set(read_state_3)
  )
  .pipe ->
    ok(true, "保存完了")
    app.read_state.get_by_board(app.url.thread_to_board(read_state_1.url))
  .pipe (res) ->
    deepEqual(res, [read_state_1, read_state_2, read_state_3], "取得確認")
    $.when(
      app.read_state.remove(read_state_1.url)
      app.read_state.remove(read_state_2.url)
      app.read_state.remove(read_state_3.url)
    )
  .pipe ->
    ok(true, "削除完了")
    app.read_state.get_by_board(app.url.thread_to_board(read_state_1.url))
  .pipe (res) ->
    deepEqual(res, [], "削除確認")
    start()

test "期待しない引数が与えられた場合はrejectする", 33, ->
  app.read_state.set().fail -> ok(true)
  app.read_state.set(123).fail -> ok(true)
  app.read_state.set([]).fail -> ok(true)
  app.read_state.set({}).fail -> ok(true)
  app.read_state.set(null).fail -> ok(true)
  app.read_state.set(undefined).fail -> ok(true)

  app.read_state.set(url: "").fail -> ok(true)
  app.read_state.set(last: 123).fail -> ok(true)
  app.read_state.set(read: 123).fail -> ok(true)
  app.read_state.set(received: 123).fail -> ok(true)
  app.read_state.set(last: 123, read: 123, received: 123).fail -> ok(true)
  app.read_state.set(url: "", read: 123, received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: 123, received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: 123, read: 123).fail -> ok(true)
  app.read_state.set(url: 123, last: 123, read: 123, received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: "123", read: 123, received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: 123, read: "123", received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: 123, read: 123, received: "123").fail -> ok(true)
  app.read_state.set(url: "", last: NaN, read: 123, received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: 123, read: NaN, received: 123).fail -> ok(true)
  app.read_state.set(url: "", last: 123, read: 123, received: NaN).fail -> ok(true)

  app.read_state.get().fail -> ok(true)
  app.read_state.get(123).fail -> ok(true)
  app.read_state.get([]).fail -> ok(true)
  app.read_state.get({}).fail -> ok(true)
  app.read_state.get(null).fail -> ok(true)
  app.read_state.get(undefined).fail -> ok(true)

  app.read_state.get_by_board().fail -> ok(true)
  app.read_state.get_by_board(123).fail -> ok(true)
  app.read_state.get_by_board([]).fail -> ok(true)
  app.read_state.get_by_board({}).fail -> ok(true)
  app.read_state.get_by_board(null).fail -> ok(true)
  app.read_state.get_by_board(undefined).fail -> ok(true)

asyncTest "SQLインジェクションを引き起こす文字列も問題なく扱える", 8, ->
  read_state =
    url: "'; DELETE FROM ReadState --"
    last: 123
    read: 123
    received: 123

  app.read_state.set(read_state)
  .pipe ->
    ok(true, "set: 成功")
    app.read_state.get(read_state.url)
  .pipe (res) ->
    ok(true, "get: 成功")
    deepEqual(res, read_state, "get: データ確認")
    app.read_state.get_by_board(read_state.url)
  .pipe (res) ->
    ok(true, "get_by_board: 成功")
    #URLの置換の関係上、板URLの欄にURLがそのまま格納される
    #良くない挙動かもしれないけれど、わりとどうでもいいので放置
    deepEqual(res, [read_state], "get_by_board: データ確認")
    app.read_state.remove(read_state.url)
  .pipe ->
    ok(true, "remove: 成功")
    app.read_state.get(read_state.url)
  .pipe null, (res) ->
    ok(true, "get: 成功")
    deepEqual(res, undefined, "get: データ確認")
    start()

