describe "app.History", ->
  "use strict"

  data1 = null
  data1add = null

  beforeEach ->
    date = Date.now()

    data1 = [
      {url: "http://example.com/1", title: "example", date: date - 0}
      {url: "http://example.com/2", title: "example", date: date - 1}
      {url: "http://example.com/3", title: "example", date: date - 2}
      {url: "http://example.com/4", title: "example", date: date - 3}
      {url: "http://example.com/5", title: "example", date: date - 4}
    ]

    data1add = ->
      $.Deferred (d) ->
        tmp = []

        fn = (row) ->
          tmp.push(app.History.add(row.url, row.title, row.date))
          return

        fn(data1[4]); fn(data1[1]); fn(data1[0]); fn(data1[2]); fn(data1[3])

        $.when.apply(null, tmp).done(-> d.resolve(); return)
        return
    return

  it "履歴を格納/取得出来る", ->
    row = data1[0]

    promise = app.History.add(row.url, row.title, row.date)

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.History.get(0, 1)
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (res) ->
        expect(res).toEqual([row])
        return
      return
    return

  it "取得した履歴は新しい順にソートされている", ->
    promise = data1add().promise()

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.History.get(0, data1.length)
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (res) ->
        expect(res).toEqual(data1)
        return
      return
    return

  it "履歴取得の開始位置を指定出来る", ->
    promise = data1add().promise()

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.History.get(2, data1.length - 2)
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (res) ->
        expect(res).toEqual(data1.slice(2))
      return
    return

  it "履歴の取得数を指定出来る", ->
    promise = data1add().promise()

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.History.get(0, data1.length - 3)
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (res) ->
        expect(res).toEqual(data1.slice(0, data1.length - 3))
        return
      return
    return


  it "履歴の件数を取得出来る", ->
    row = data1[0]
    before = null

    promise = app.History.count()

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (count) ->
        before = count
        return

      promise = data1add().promise()
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.History.count()
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (count) ->
        expect(count).toBe(before + data1.length)
        return
      return
    return

  it "期待されない引数が渡された場合、rejectする", ->
    expect(app.History.add("test").state()).toBe("rejected")
    expect(app.History.add("test", "test").state()).toBe("rejected")
    expect(app.History.add("test", "test", "123").state()).toBe("rejected")
    expect(app.History.add("test", 123, 123).state()).toBe("rejected")
    expect(app.History.add(123, "test", 123).state()).toBe("rejected")
    expect(app.History.add(null, "test", 123).state()).toBe("rejected")
    expect(app.History.add("test", null, 123).state()).toBe("rejected")
    expect(app.History.add("test", "test", null).state()).toBe("rejected")
    expect(app.History.get("test", null).state()).toBe("rejected")
    expect(app.History.get(null, "test").state()).toBe("rejected")
    expect(app.History.get("test", "test").state()).toBe("rejected")
    return

  it "SQLインジェクションを引き起こす文字列も問題無く格納出来る", ->
    # app.history.getは数値以外の引数を無視するので省略
    # app.history.clearは引数を取らないので省略

    date = Date.now()
    data1 = [
      {url: "http://example.com/1", title: ",", date: date - 0}
      {url: "http://example.com/2", title: ";", date: date - 1}
      {url: ",", title: "example", date: date - 2}
      {url: ";", title: "example", date: date - 3}
      {url: "'; DELETE FROM History --", title: "'; DELETE FROM History --", date: date - 4}
    ]

    promise = data1add().promise()

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.History.get(0, data1.length)
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (res) ->
        expect(res).toEqual(data1)
        return
      return
    return
  return
