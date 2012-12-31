describe "app.util.Anchor", ->
  describe "app.util.Anchor.reg.ANCHOR", ->
    match = (str, match) ->
      reg = new RegExp(app.util.Anchor.reg.ANCHOR)

      if match is null
        expect(str).not.toMatch(app.util.Anchor.reg.ANCHOR)
      else
        match ?= str

        expect(str).toMatch(app.util.Anchor.reg.ANCHOR)
        expect(reg.exec(str)[0]).toBe(match)
      return

    it "正しい形式のアンカーにマッチする", ->
      match("&gt;&gt;1")
      match("&gt;1")
      match("＞＞1")
      match("＞1")
      match(">>1", null)
      match(">1", null)

      match("&gt;&gt;1-3")
      match("&gt;&gt;10-25")
      match("&gt;&gt;1ー3")

      match("&gt;&gt;1, 2")
      match("&gt;&gt;1,2,3 ,", "&gt;&gt;1,2,3")
      match("&gt;&gt;1,    2, 3,", "&gt;&gt;1,    2, 3")

      match("&gt;&gt;1,2-10,12 ,", "&gt;&gt;1,2-10,12")

      match("&gt;&gt;-1", null)
      return
    return

  describe "app.util.Anchor.parseAnchor", ->
    it "アンカーをパースする", ->
      expect(app.util.Anchor.parseAnchor("&gt;1"))
        .toEqual(targetCount: 1, segments: [[1, 1]])
      return

    it "ハイフンで範囲指定が出来る", ->
      expect(app.util.Anchor.parseAnchor("&gt;1-3"))
        .toEqual(targetCount: 3, segments: [[1, 3]])

      expect(app.util.Anchor.parseAnchor("&gt;10-25"))
        .toEqual(targetCount: 16, segments: [[10, 25]])
      return

    it "カンマで区切って複数の範囲を指定出来る", ->
      expect(app.util.Anchor.parseAnchor("&gt;1, 2"))
        .toEqual(targetCount: 2, segments: [[1, 1], [2, 2]])

      expect(app.util.Anchor.parseAnchor("&gt;1,2,3"))
        .toEqual(targetCount: 3, segments: [[1, 1], [2, 2], [3, 3]])

      expect(app.util.Anchor.parseAnchor("&gt;1,    2, 3"))
        .toEqual(targetCount: 3, segments: [[1, 1], [2, 2], [3, 3]])
      return

    it "範囲指定とカンマ区切りの同時利用も可能", ->
      expect(app.util.Anchor.parseAnchor("&gt;1,2-10,12"))
        .toEqual(targetCount: 11, segments: [[1, 1], [2, 10], [12, 12]])
      return

    it "明確に有り得ない範囲指定は無視する", ->
      expect(app.util.Anchor.parseAnchor("&gt;0"))
        .toEqual(targetCount: 0, segments: [])

      expect(app.util.Anchor.parseAnchor("&gt;0-1"))
        .toEqual(targetCount: 0, segments: [])

      expect(app.util.Anchor.parseAnchor("&gt;-1"))
        .toEqual(targetCount: 0, segments: [])

      expect(app.util.Anchor.parseAnchor("&gt;2-1"))
        .toEqual(targetCount: 0, segments: [])

      expect(app.util.Anchor.parseAnchor("&gt;1-3, 5-1, 4-6, 2002-1"))
        .toEqual(targetCount: 6, segments: [[1, 3], [4, 6]])
      return

    it "6桁以上のレス番号の指定は無視する", ->
      expect(app.util.Anchor.parseAnchor("&gt;10000"))
        .toEqual(targetCount: 1, segments: [[10000, 10000]])

      expect(app.util.Anchor.parseAnchor("&gt;100000"))
        .toEqual(targetCount: 0, segments: [])

      expect(app.util.Anchor.parseAnchor("&gt;1000000"))
        .toEqual(targetCount: 0, segments: [])

      expect(app.util.Anchor.parseAnchor("&gt;1-3, 2-333333, 4-6, 777777-8"))
        .toEqual(targetCount: 6, segments: [[1, 3], [4, 6]])
      return

    it "全角数字を半角数字と同様に扱う", ->
      expect(app.util.Anchor.parseAnchor("&gt;１"))
        .toEqual(targetCount: 1, segments: [[1, 1]])

      expect(app.util.Anchor.parseAnchor("&gt;1-３, ４"))
        .toEqual(targetCount: 4, segments: [[1, 3], [4, 4]])
      return

    it "全角ダッシュをハイフンと同様に扱う", ->
      expect(app.util.Anchor.parseAnchor("&gt;1ー3"))
        .toEqual(targetCount: 3, segments: [[1, 3]])
      return
    return
  return
