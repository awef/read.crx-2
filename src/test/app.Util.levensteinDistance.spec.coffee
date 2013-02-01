describe "app.Util.levenshteinDistance", ->
  it "レーベンシュタイン距離（編集距離）を算出する", ->
    data = [
      ["", "", 0]
      ["a", "a", 0]
      ["テスト", "テスト", 0]
      ["", "a", 1]
      ["a", "", 1]
      ["a", "b", 1]
      ["b", "a", 1]
      ["test", "test", 0]
      ["tast", "test", 1]
      ["test", "tast", 1]
      ["快晴", "曇天", 2]
      ["google", "apple", 4]
      ["apple", "google", 4]
      ["apple", "     apple", 5]
      ["aaaaaa", "bbbbbb", 6]
    ]

    for entry in data
      expect(app.Util.levenshteinDistance(entry[0], entry[1])).toBe(entry[2])
    return

  it "置換を許可（コスト1として算出）するかどうか設定できる", ->
    data = [
      ["", "", 0, false]
      ["", "", 0, true]
      ["", "a", 1, true]
      ["", "a", 1, false]
      ["a", "", 1, true]
      ["a", "", 1, false]
      ["a", "b", 1, true]
      ["a", "b", 2, false]
      ["test", "test part1", 6, true]
      ["test", "test part1", 6, false]
      ["test", "hoge", 4, true]
      ["test", "hoge", 6, false]
    ]

    for entry in data
      expect(app.Util.levenshteinDistance(entry[0], entry[1], entry[3]))
        .toBe(entry[2])
    return
  return
