module("app.bbsmenu")

test "パースエラーテスト", ->
  strictEqual(app.bbsmenu.parse(""), null, "空文字列")
