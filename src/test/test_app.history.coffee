module "app.history",
  # 履歴データの閲覧日時順ソートに依存したテストなので、場合によってはコードに問題が無くても失敗する
  setup: ->
    date = Date.now()
    @data_1 = [
      {url: "http://example.com/1", title: "example", date: date - 0}
      {url: "http://example.com/2", title: "example", date: date - 1}
      {url: "http://example.com/3", title: "example", date: date - 2}
      {url: "http://example.com/4", title: "example", date: date - 3}
      {url: "http://example.com/5", title: "example", date: date - 4}
    ]
    @data_1_add = ->
      tmp = []
      fn = (row) -> tmp.push(app.history.add(row.url, row.title, row.date))
      fn(@data_1[4]); fn(@data_1[1]); fn(@data_1[0]); fn(@data_1[2])
      fn(@data_1[3])
      $.when.apply(null, tmp)

asyncTest "履歴を格納/取得出来る", 1, ->
  row = @data_1[0]
  app.history.add(row.url, row.title, row.date)
    .done ->
      app.history.get(0, 1)
        .done (res) ->
          deepEqual(res[0], row)
          start()

asyncTest "取得した履歴は新しい順にソートされている", 1, ->
  @data_1_add().done =>
    app.history.get(0, @data_1.length)
      .done (res) =>
        deepEqual(res, @data_1)
        start()

asyncTest "履歴の開始位置を指定出来る", 1, ->
  @data_1_add().done =>
    app.history.get(2, @data_1.length - 2)
      .done (res) =>
        deepEqual(res, @data_1.slice(2))
        start()

asyncTest "履歴の取得数を指定出来る", 1, ->
  @data_1_add().done =>
    app.history.get(0, @data_1.length - 3)
      .done (res) =>
        deepEqual(res, @data_1.slice(0, @data_1.length - 3))
        start()

test "期待されない引数が渡された場合、rejectする", 11, ->
  app.history.add("test").fail -> ok(true)
  app.history.add("test", "test").fail -> ok(true)
  app.history.add("test", "test", "123").fail -> ok(true)
  app.history.add("test", 123, 123).fail -> ok(true)
  app.history.add(123, "test", 123).fail -> ok(true)
  app.history.add(null, "test", 123).fail -> ok(true)
  app.history.add("test", null, 123).fail -> ok(true)
  app.history.add("test", "test", null).fail -> ok(true)
  app.history.get("test", null).fail -> ok(true)
  app.history.get(null, "test").fail -> ok(true)
  app.history.get("test", "test").fail -> ok(true)

asyncTest "SQLインジェクションを引き起こす文字列も問題無く格納出来る", 1, ->
  # app.history.getは数値以外の引数を無視するので省略（別のテストできちんとチェック）
  # app.history.clearは引数を取らないので省略
  date = Date.now()
  tmp =
    data_1: [
      {url: "http://example.com/1", title: ",", date: date - 0}
      {url: "http://example.com/2", title: ";", date: date - 1}
      {url: ",", title: "example", date: date - 2}
      {url: ";", title: "example", date: date - 3}
      {url: "'; DELETE FROM History --", title: "'; DELETE FROM History --", date: date - 4}
    ]
  @data_1_add.apply(tmp)
   .done =>
     app.history.get(0, tmp.data_1.length)
      .done (res) =>
        deepEqual(res, tmp.data_1)
        start()
