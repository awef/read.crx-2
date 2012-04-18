module("euc_jp_escape.escape")

asyncTest "文字列をeuc-jpのサイト向け文字列にエスケープする", 1, ->
  source = "Google\"> Chrome 拡張"
  app.module null, ["euc_jp_escape"], (euc_jp_escape) ->
    euc_jp_escape.escape(source).done (result) ->
      strictEqual(result, "Google%22%3E+Chrome+%B3%C8%C4%A5", source)
      start()
      return
    return
  return
