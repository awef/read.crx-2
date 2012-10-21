describe "app.deep_copy", ->
  original = null

  beforeEach ->
    original =
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
    return

  it "通常の代入時", ->
    copy = original

    expect(copy).toBe(original)
    expect(copy).toEqual(original)

    copy.test = 321

    expect(copy).toEqual(original)
    return

  it "deep_copy使用時", ->
    copy = app.deep_copy(original)

    expect(copy).not.toBe(original)

    # jasmineはNaNが有るとtoEqualが通らないので、その対策
    expect(isNaN(original.test4.test7[4])).toBeTruthy()
    expect(isNaN(copy.test4.test7[4])).toBeTruthy()
    original.test4.test7[4] = "dummy"
    copy.test4.test7[4] = "dummy"

    expect(copy).toEqual(original)

    copy.test = 321

    expect(copy).not.toEqual(original)
    return

describe "app.defer", ->
  it "渡された関数を非同期で実行する", ->
    fn = jasmine.createSpy()

    app.defer(fn)

    expect(fn).not.toHaveBeenCalled()

    waitsFor ->
      fn.wasCalled

    runs ->
      expect(fn.callCount).toBe(1)
      return
    return
  return

describe "app.safe_href", ->
  it "与えられた文字列がhttp, https以外のURLだった場合、ダミーURLを返す", ->
    expect(app.safe_href("http://example.com/")).toBe("http://example.com/")
    expect(app.safe_href("https://example.com/")).toBe("https://example.com/")
    expect(app.safe_href(" http://example.com/")).toBe("/view/empty.html")
    expect(app.safe_href(" https://example.com/")).toBe("/view/empty.html")
    expect(app.safe_href("")).toBe("/view/empty.html")
    expect(app.safe_href("javascript:undefined;")).toBe("/view/empty.html")
    expect(app.safe_href("data:text/plain,test")).toBe("/view/empty.html")
    return
  return

describe "app.escape_html", ->
  it "与えられた文字列中の<>\"'&をエスケープする", ->
    expect(app.escape_html(""" <a href="'#'">test&test&test</a> """))
      .toBe(""" &lt;a href=&quot;&apos;#&apos;&quot;&gt;test&amp;test&amp;test&lt;/a&gt; """)
    return
  return

describe "app.module", ->
  it "非同期にモジュールを定義する事が出来る", ->
    step = 0

    app.module "__a", [], (callback) ->
      expect(++step).toBe(2)
      callback(x: 123)
      return

    app.module "__b", ["__a"], (__a, callback) ->
      expect(++step).toBe(3)
      expect(__a).toEqual(x: 123)
      callback(y: 234)
      return

    app.module "__c", ["__b", "__a"], (__b, __a, callback) ->
      expect(++step).toBe(4)
      expect(__b).toEqual(y: 234)
      expect(__a).toEqual(x: 123)
      callback({})
      return

    expect(++step).toBe(1)

    waitsFor ->
      step is 4
    return

  it "依存関係が満たされるまで、モジュールの初期化は行われない", ->
    step = 0

    app.module "__d", [], (callback) ->
      expect(++step).toBe(2)
      callback(x: 123)
      return

    app.module "__f", ["__d", "__e"], (__d, __e, callback) ->
      expect(++step).toBe(4)
      expect(__d).toEqual(x: 123)
      expect(__e).toEqual(y: 234)
      callback({})
      return

    app.module "__e", [], (callback) ->
      expect(++step).toBe(3)
      callback(y: 234)
      return

    expect(++step).toBe(1)

    waitsFor ->
      step is 4
    return

  it "モジュール名がnullの場合は依存関係の解決のみ行う", ->
    step = 0

    app.module null, ["__g"], (__g) ->
      expect(++step).toBe(3)
      expect(arguments.length).toBe(1)
      expect(__g).toEqual(a: "test")
      return

    app.module null, ["__g"], (__g) ->
      expect(++step).toBe(4)
      expect(arguments.length).toBe(1)
      expect(__g).toEqual(a: "test")
      return

    app.module "__g", [], (callback) ->
      expect(++step).toBe(2)
      callback(a: "test")
      return

    expect(++step).toBe(1)

    waitsFor ->
      step is 4
    return
  return
