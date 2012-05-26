module "History",
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
      data_1 = @data_1
      $.Deferred (d) ->
        app.module null, ["history"], (History) ->
          tmp = []
          fn = (row) -> tmp.push(History.add(row.url, row.title, row.date))
          fn(data_1[4]); fn(data_1[1]); fn(data_1[0]); fn(data_1[2])
          fn(data_1[3])
          $.when.apply(null, tmp).done(-> d.resolve(); return)
          return
        return
    return

asyncTest "履歴を格納/取得出来る", 1, ->
  row = @data_1[0]
  app.module null, ["history"], (History) ->
    History.add(row.url, row.title, row.date).done ->
      History.get(0, 1).done (res) ->
        deepEqual(res[0], row)
        start()
        return
      return
    return
  return

asyncTest "取得した履歴は新しい順にソートされている", 1, ->
  app.module null, ["history"], (History) =>
    @data_1_add().done =>
      History.get(0, @data_1.length).done (res) =>
        deepEqual(res, @data_1)
        start()
      return
    return
  return

asyncTest "履歴の開始位置を指定出来る", 1, ->
  app.module null, ["history"], (History) =>
    @data_1_add().done =>
      History.get(2, @data_1.length - 2).done (res) =>
        deepEqual(res, @data_1.slice(2))
        start()
        return
      return
    return
  return

asyncTest "履歴の取得数を指定出来る", 1, ->
  app.module null, ["history"], (History) =>
    @data_1_add().done =>
      History.get(0, @data_1.length - 3).done (res) =>
        deepEqual(res, @data_1.slice(0, @data_1.length - 3))
        start()
        return
      return
    return
  return

asyncTest "履歴の件数を取得出来る", 1, ->
  app.module null, ["history"], (History) =>
    row = @data_1[0]
    before = null
    @data_1_add()
      .pipe ->
        History.count()
      .pipe (count) ->
        before = count
        History.add(row.url, row.title, row.date)
      .pipe ->
        History.count()
      .pipe (count) ->
        strictEqual(count - before, 1)
        start()
        return
    return
  return

asyncTest "期待されない引数が渡された場合、rejectする", 1, ->
  app.module null, ["history"], (History) =>
    History.add("test").pipe null, ->
    History.add("test", "test").pipe null, ->
    History.add("test", "test", "123").pipe null, ->
    History.add("test", 123, 123).pipe null, ->
    History.add(123, "test", 123).pipe null, ->
    History.add(null, "test", 123).pipe null, ->
    History.add("test", null, 123).pipe null, ->
    History.add("test", "test", null).pipe null, ->
    History.get("test", null).pipe null, ->
    History.get(null, "test").pipe null, ->
    History.get("test", "test").pipe null, -> ok(true); start()
    return
  return

asyncTest "SQLインジェクションを引き起こす文字列も問題無く格納出来る", 1, ->
  # app.history.getは数値以外の引数を無視するので省略（別のテストできちんとチェック）
  # app.history.clearは引数を取らないので省略
  app.module null, ["history"], (History) =>
    date = Date.now()
    tmp =
      data_1: [
        {url: "http://example.com/1", title: ",", date: date - 0}
        {url: "http://example.com/2", title: ";", date: date - 1}
        {url: ",", title: "example", date: date - 2}
        {url: ";", title: "example", date: date - 3}
        {url: "'; DELETE FROM History --", title: "'; DELETE FROM History --", date: date - 4}
      ]
    @data_1_add.apply(tmp).done =>
      History.get(0, tmp.data_1.length).done (res) =>
        deepEqual(res, tmp.data_1)
        start()
        return
    return
  return
