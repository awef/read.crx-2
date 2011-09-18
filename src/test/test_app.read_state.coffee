module("app.read_state")

asyncTest "read_stateの保存/取得/削除が出来る", 6, ->
  original_read_state =
    url: "http://dummyserver.2ch.net/test/read.cgi/dummyboard/1234/"
    last: 123
    read: 234
    received: 345

  #read_stateの保存
  app.read_state.set(original_read_state)
    .pipe ->
      ok(true, "read_state.set")
      #スレURLからread_stateを取得
      app.read_state.get(original_read_state.url)
    , ->
      ok(false, "read_state.set")

    .pipe (read_state) ->
      deepEqual(read_state, original_read_state, "read_state.get")
      #板URLからread_stateを取得
      app.read_state.get_by_board(app.url.thread_to_board(original_read_state.url))
    , ->
      ok(false, "read_state.get")

    .pipe (data) ->
      deepEqual(data, [original_read_state], "read_state.get_by_board")
      #read_stateの削除
      app.read_state.remove(original_read_state.url)
    , ->
      ok(false, "read_state.get_by_board")

    .pipe ->
      ok(true, "read_state.remove")
      #ちゃんと消えているのかの確認
      app.read_state.get(original_read_state.url)
    , ->
      ok(false, "read_state.remove")

    .pipe (read_state) ->
      strictEqual(read_state, undefined, "read_state.remove 確認")
      #ちゃんと消えているのかの確認（板URLで取得編）
      app.read_state.get_by_board(app.url.thread_to_board(original_read_state.url))
    , ->
      ok(false, "read_state.remove 確認")

    .pipe (result) ->
      deepEqual(result, [], "read_state.remove 確認2")
    , ->
      ok(false, "read_state.remove 確認2")

    .always ->
      start()
