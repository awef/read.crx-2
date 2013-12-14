module("Board._get_xhr_info")

asyncTest "板のURLから、データのパスと文字コードを返す", 6, ->
  app.module null, ["board"], (Board) ->
    pattern = [
      {
        message: "2ch"
        url: "http://qb5.2ch.net/operate/"
        path: "http://qb5.2ch.net/operate/subject.txt"
        charset: "Shift_JIS"
      }
      {
        message: "まちBBS"
        url: "http://www.machi.to/tawara/"
        path: "http://www.machi.to/bbs/offlaw.cgi/tawara/"
        charset: "Shift_JIS"
      }
      {
        message: "したらば"
        url: "http://jbbs.livedoor.jp/computer/42710/"
        path: "http://jbbs.shitaraba.net/computer/42710/subject.txt"
        charset: "EUC-JP"
      }
      {
        message: "したらば"
        url: "http://jbbs.shitaraba.net/computer/42710/"
        path: "http://jbbs.shitaraba.net/computer/42710/subject.txt"
        charset: "EUC-JP"
      }
      {
        message: "BBSPINK"
        url: "http://pele.bbspink.com/erobbs/"
        path: "http://pele.bbspink.com/erobbs/subject.txt"
        charset: "Shift_JIS"
      }
      {
        message: "パー速VIP"
        url: "http://ex14.vip2ch.com/part4vip/"
        path: "http://ex14.vip2ch.com/part4vip/subject.txt"
        charset: "Shift_JIS"
      }
    ]

    for tmp in pattern
      deepEqual(Board._get_xhr_info(tmp.url), {path: tmp.path, charset: tmp.charset}, tmp.message)

    start()
    return
  return

module "Board.parse",
  setup: ->
    @test = (url, text, expected) ->
      app.module null, ["board"], (Board) ->
        deepEqual(Board.parse(url, text), expected)
        start()
        return
      return
    return

asyncTest "2chのスレ覧をパース出来る", 1, ->
  url = "http://qb5.2ch.net/operate/"
  text = """
    1301664644.dat<>【粛々と】シークレット★忍法帖巻物 8【情報収集、集約スレ】 (174)
    1301751706.dat<>【news】ニュース速報運用情報759【ν】 (221)
    1301761019.dat<>[test] 書き込みテスト 専用スレッド 240 [ﾃｽﾄ] (401)
    1295975106.dat<>重い重い重い重い重い重い重い×70＠運用情報 (668)
    1294363063.dat<>【お止め組。】出動予定＆連絡 詰所◆13 (312)
  """
  expected = [
    {
      url: "http://qb5.2ch.net/test/read.cgi/operate/1301664644/"
      title: "【粛々と】シークレット★忍法帖巻物 8【情報収集、集約スレ】"
      res_count: 174
      created_at: 1301664644000
    }
    {
      url: "http://qb5.2ch.net/test/read.cgi/operate/1301751706/"
      title: "【news】ニュース速報運用情報759【ν】"
      res_count: 221
      created_at: 1301751706000
    }
    {
      url: "http://qb5.2ch.net/test/read.cgi/operate/1301761019/"
      title: "[test] 書き込みテスト 専用スレッド 240 [ﾃｽﾄ]"
      res_count: 401
      created_at: 1301761019000
    }
    {
      url: "http://qb5.2ch.net/test/read.cgi/operate/1295975106/"
      title: "重い重い重い重い重い重い重い×70＠運用情報"
      res_count: 668
      created_at: 1295975106000
    }
    {
      url: "http://qb5.2ch.net/test/read.cgi/operate/1294363063/"
      title: "【お止め組。】出動予定＆連絡 詰所◆13"
      res_count: 312,
      created_at: 1294363063000
    }
  ]
  @test(url, text, expected)
  return

asyncTest "まちBBSのスレ覧をパース出来る", 1, ->
  url = "http://www.machi.to/tawara/"
  text = """
    1<>1269441710<>～削除依頼はこちらから～(1)
    2<>1299160555<>関東板削除依頼スレッド54(134)
    3<>1239604919<>●ホスト規制中第32巻●(973)
    4<>1300530242<>東北板　削除依頼スレッド【Part38】(210)
    5<>1187437274<>東北板管理人**********不信任スレ(350)
  """
  expected = [
    {
      url: "http://www.machi.to/bbs/read.cgi/tawara/1269441710/"
      title: "～削除依頼はこちらから～"
      res_count: 1
      created_at: 1269441710000
    }
    {
      url: "http://www.machi.to/bbs/read.cgi/tawara/1299160555/"
      title: "関東板削除依頼スレッド54"
      res_count: 134
      created_at: 1299160555000
    }
    {
      url: "http://www.machi.to/bbs/read.cgi/tawara/1239604919/"
      title: "●ホスト規制中第32巻●"
      res_count: 973
      created_at: 1239604919000
    }
    {
      url: "http://www.machi.to/bbs/read.cgi/tawara/1300530242/"
      title: "東北板　削除依頼スレッド【Part38】"
      res_count: 210
      created_at: 1300530242000
    }
    {
      url: "http://www.machi.to/bbs/read.cgi/tawara/1187437274/"
      title: "東北板管理人**********不信任スレ"
      res_count: 350
      created_at: 1187437274000
    }
  ]
  @test(url, text, expected)
  return

asyncTest "したらばのスレ覧をパース出来る", 1, ->
  url = "http://jbbs.shitaraba.net/computer/42710/"
  text = """
    1290070091.cgi,read.crx総合 part2(354)
    1290070123.cgi,read.crx CSSスレ(31)
    1273802908.cgi,read.crx総合(1000)
    1273732874.cgi,テストスレ(413)
    1273734819.cgi,スレスト(1)
    1290070091.cgi,read.crx総合 part2(354)
  """
  expected = [
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/computer/42710/1290070091/"
      title: "read.crx総合 part2"
      res_count: 354
      created_at: 1290070091000
    }
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/computer/42710/1290070123/"
      title: "read.crx CSSスレ"
      res_count: 31
      created_at: 1290070123000
    }
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/computer/42710/1273802908/"
      title: "read.crx総合"
      res_count: 1000
      created_at: 1273802908000
    }
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/computer/42710/1273732874/"
      title: "テストスレ"
      res_count: 413
      created_at: 1273732874000
    }
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/computer/42710/1273734819/"
      title: "スレスト"
      res_count: 1
      created_at: 1273734819000
    }
  ]
  @test(url, text, expected)
  return

asyncTest "BBSPINKのスレ覧をパース出来る", 1, ->
  url = "http://pele.bbspink.com/erobbs/"
  text = """
    9241103704.dat<>■　現在の電力情況(東電)、節電する? いつまで続く? (13)
    9241103901.dat<>■東北地方太平洋沖地震 (3)
    1299998629.dat<>Let\"s talk with ***-san. Part18 (157)
    1246751830.dat<>チラシの裏 (714)
    1202732336.dat<>削除人さんと案内人さんと、酢豚の★さんを募集 (227)
  """
  expected = [
    {
      url: "http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/"
      title: "■　現在の電力情況(東電)、節電する? いつまで続く?"
      res_count: 13
      created_at: 9241103704000
    }
    {
      url: "http://pele.bbspink.com/test/read.cgi/erobbs/9241103901/"
      title: "■東北地方太平洋沖地震"
      res_count: 3
      created_at: 9241103901000
    }
    {
      url: "http://pele.bbspink.com/test/read.cgi/erobbs/1299998629/"
      title: "Let\"s talk with ***-san. Part18"
      res_count: 157
      created_at: 1299998629000
    }
    {
      url: "http://pele.bbspink.com/test/read.cgi/erobbs/1246751830/"
      title: "チラシの裏"
      res_count: 714
      created_at: 1246751830000
    }
    {
      url: "http://pele.bbspink.com/test/read.cgi/erobbs/1202732336/"
      title: "削除人さんと案内人さんと、酢豚の★さんを募集"
      res_count: 227
      created_at: 1202732336000
    }
  ]
  @test(url, text, expected)
  return

asyncTest "パー速VIPのスレ覧をパース出来る", 1, ->
  url = "http://ex14.vip2ch.com/part4vip/"
  text = """
    1301741923.dat<>バイト先の好きな子にプレゼントあげたんだが (128)
    1301054675.dat<>住ックス (912)
    1300609713.dat<>VIPでエバープラネット避難所 (134)
    1301596001.dat<>【避難所】VIPSPo2iファンタシースターポータブル2インフィニティ (524)
    1300631086.dat<>ここだけ魔法世界　792回のどんでん返し (602)
  """
  expected = [
    {
      url: "http://ex14.vip2ch.com/test/read.cgi/part4vip/1301741923/"
      title: "バイト先の好きな子にプレゼントあげたんだが"
      res_count: 128
      created_at: 1301741923000
    }
    {
      url: "http://ex14.vip2ch.com/test/read.cgi/part4vip/1301054675/"
      title: "住ックス"
      res_count: 912
      created_at: 1301054675000
    }
    {
      url: "http://ex14.vip2ch.com/test/read.cgi/part4vip/1300609713/"
      title: "VIPでエバープラネット避難所"
      res_count: 134
      created_at: 1300609713000
    }
    {
      url: "http://ex14.vip2ch.com/test/read.cgi/part4vip/1301596001/"
      title: "【避難所】VIPSPo2iファンタシースターポータブル2インフィニティ"
      res_count: 524
      created_at: 1301596001000
    }
    {
      url: "http://ex14.vip2ch.com/test/read.cgi/part4vip/1300631086/"
      title: "ここだけ魔法世界　792回のどんでん返し"
      res_count: 602
      created_at: 1300631086000
    }
  ]
  @test(url, text, expected)
  return

asyncTest "パースに失敗した場合はnullを返す", 70, ->
  app.module null, ["board"], (Board) ->
    pattern = [
      ""
      "<>"
      "dummy"
      "<>dummy"
      "dummy<>"
      "<>dummy<>"
      "<><>"
      "dummy<>dummy"
      "<>dummy<>dummy"
      "dummy<>dummy<>"
      "<>dummy<>dummy<>"
      "<>dummy<><>"
      "<><>dummy<>"
      "<><><>"
    ]

    for text in pattern
      strictEqual(Board.parse("http://qb5.2ch.net/operate/", text), null)
      strictEqual(Board.parse("http://www.machi.to/tawara/", text), null)
      strictEqual(Board.parse("http://jbbs.livedoor.jp/computer/42710/", text), null)
      strictEqual(Board.parse("http://pele.bbspink.com/erobbs/", text), null)
      strictEqual(Board.parse("http://ex14.vip2ch.com/part4vip/", text), null)

    start()
    return
  return

module "Board::get",
  setup: ->
    #200 -> 304 -> 200
    @test = (config) -> # url, dat_url, dat, expected
      app.module null, ["cache", "board"], (Cache, Board) ->
        mock =
          etag: null
          last_modified: null
          update: ->
            @etag = Date.now().toString(36) + "-" + Date.now().toString(36)
            @last_modified = (new Date()).toUTCString()
            return

        board = new Board(config.url)

        #初回取得準備(200)
        $.Deferred (d) ->
          QUnit.step(1)

          mock.update()

          $.mockjax
            url: config.dat_url
            status: 200
            headers:
              "ETag": mock.etag
              "Last-Modified": mock.last_modified
            responseText: config.dat1
            response: (ajax_settings) ->
              QUnit.step(3)
              deepEqual(ajax_settings.headers, {}, "初回取得時リクエストヘッダ")
              return

          new Cache(config.dat_url).delete().done(d.resolve)
        #初回取得(200)
        .pipe -> $.Deferred (d) ->
          QUnit.step(2)

          board.get().done ->
            QUnit.step(4)
            $.mockjaxClear()
            strictEqual(board.message, null, "初回取得後board.message")
            deepEqual(board.thread, config.expected1, "初回取得後board.thread")
            d.resolve()
            return
        #過剰リロード防止機構回避
        .pipe -> $.Deferred (d) ->
          setTimeout(d.resolve, 3500)
          return
        #二回目取得（更新無し）
        .pipe -> $.Deferred (d) ->
          QUnit.step(5)
          $.mockjax
            url: config.dat_url
            status: 304
            responseText: ""
            response: (ajax_settings) ->
              QUnit.step(6)
              deepEqual(ajax_settings.headers, {
                  "If-Modified-Since": mock.last_modified
                  "If-None-Match": mock.etag
                }, "二回目取得時リクエストヘッダ")
              return

          board.get().done ->
            QUnit.step(7)
            $.mockjaxClear()
            strictEqual(board.message, null, "二回目取得後board.message")
            deepEqual(board.thread, config.expected1, "二回目取得後board.thread")
            d.resolve()
            return
          return
        #過剰リロード防止機構回避
        .pipe -> $.Deferred (d) ->
          setTimeout(d.resolve, 3500)
          return
        #三回目取得
        .pipe -> $.Deferred (d) ->
          QUnit.step(8)

          old_last_modified = mock.last_modified
          old_etag = mock.etag
          mock.update()

          $.mockjax
            url: config.dat_url
            status: 200
            headers:
              "ETag": mock.etag
              "Last-Modified": mock.last_modified
            responseText: config.dat2
            response: (ajax_settings) ->
              QUnit.step(9)
              deepEqual(ajax_settings.headers, {
                  "If-Modified-Since": old_last_modified
                  "If-None-Match": old_etag
                }, "二回目取得時リクエストヘッダ")
              return

          board.get().done ->
            QUnit.step(10)
            $.mockjaxClear()
            strictEqual(board.message, null, "二回目取得後board.message")
            deepEqual(board.thread, config.expected2, "二回目取得後board.thread")
            d.resolve()
            return
          return
        .done(start)
        return
      return
    return

asyncTest "2chの板の取得/更新テスト", 19, ->
  dat1 = """
    1301664644.dat<>【粛々と】シークレット★忍法帖巻物 8【情報収集、集約スレ】 (174)
    1301751706.dat<>【news】ニュース速報運用情報759【ν】 (221)
    1301761019.dat<>[test] 書き込みテスト 専用スレッド 240 [ﾃｽﾄ] (401)
  """
  dat2 = dat1 + """
    \n1295975106.dat<>重い重い重い重い重い重い重い×70＠運用情報 (668)
    1294363063.dat<>【お止め組。】出動予定＆連絡 詰所◆13 (312)
  """
  expected1 = [
    {
      url: "http://__qb5.2ch.net/test/read.cgi/operate/1301664644/"
      title: "【粛々と】シークレット★忍法帖巻物 8【情報収集、集約スレ】"
      res_count: 174
      created_at: 1301664644000
    }
    {
      url: "http://__qb5.2ch.net/test/read.cgi/operate/1301751706/"
      title: "【news】ニュース速報運用情報759【ν】"
      res_count: 221
      created_at: 1301751706000
    }
    {
      url: "http://__qb5.2ch.net/test/read.cgi/operate/1301761019/"
      title: "[test] 書き込みテスト 専用スレッド 240 [ﾃｽﾄ]"
      res_count: 401
      created_at: 1301761019000
    }
  ]
  expected2 = app.deep_copy(expected1)
  expected2.push {
    url: "http://__qb5.2ch.net/test/read.cgi/operate/1295975106/"
    title: "重い重い重い重い重い重い重い×70＠運用情報"
    res_count: 668
    created_at: 1295975106000
  }
  expected2.push {
    url: "http://__qb5.2ch.net/test/read.cgi/operate/1294363063/"
    title: "【お止め組。】出動予定＆連絡 詰所◆13"
    res_count: 312,
    created_at: 1294363063000
  }
  @test {
    url: "http://__qb5.2ch.net/operate/"
    dat_url: "http://__qb5.2ch.net/operate/subject.txt"
    dat1
    expected1
    dat2
    expected2
  }
  return

asyncTest "まちBBSの板の取得/更新テスト", 19, ->
  dat1 = """
    1<>1269441710<>～削除依頼はこちらから～(1)
    2<>1299160555<>関東板削除依頼スレッド54(134)
    3<>1239604919<>●ホスト規制中第32巻●(973)
  """
  dat2 = dat1 + """
    \n4<>1300530242<>東北板　削除依頼スレッド【Part38】(210)
    5<>1187437274<>東北板管理人**********不信任スレ(350)
  """
  expected1 = [
    {
      url: "http://__www.machi.to/bbs/read.cgi/tawara/1269441710/"
      title: "～削除依頼はこちらから～"
      res_count: 1
      created_at: 1269441710000
    }
    {
      url: "http://__www.machi.to/bbs/read.cgi/tawara/1299160555/"
      title: "関東板削除依頼スレッド54"
      res_count: 134
      created_at: 1299160555000
    }
    {
      url: "http://__www.machi.to/bbs/read.cgi/tawara/1239604919/"
      title: "●ホスト規制中第32巻●"
      res_count: 973
      created_at: 1239604919000
    }
  ]
  expected2 = app.deep_copy(expected1)
  expected2.push {
    url: "http://__www.machi.to/bbs/read.cgi/tawara/1300530242/"
    title: "東北板　削除依頼スレッド【Part38】"
    res_count: 210
    created_at: 1300530242000
  }
  expected2.push {
    url: "http://__www.machi.to/bbs/read.cgi/tawara/1187437274/"
    title: "東北板管理人**********不信任スレ"
    res_count: 350
    created_at: 1187437274000
  }
  @test {
    url: "http://__www.machi.to/tawara/"
    dat_url: "http://__www.machi.to/bbs/offlaw.cgi/tawara/"
    dat1
    expected1
    dat2
    expected2
  }
  return

asyncTest "したらばの板の取得/更新テスト", 19, ->
  dat1 = """
    1290070091.cgi,read.crx総合 part2(354)
    1290070123.cgi,read.crx CSSスレ(31)
    1273802908.cgi,read.crx総合(1000)
    1290070091.cgi,read.crx総合 part2(354)
  """
  dat2 = dat1.split("\n")[0...-1].join("\n")
  dat2 += """
    \n1273732874.cgi,テストスレ(413)
    1273734819.cgi,スレスト(1)
    1290070091.cgi,read.crx総合 part2(354)
  """
  expected1 = [
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/__computer/42710/1290070091/"
      title: "read.crx総合 part2"
      res_count: 354
      created_at: 1290070091000
    }
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/__computer/42710/1290070123/"
      title: "read.crx CSSスレ"
      res_count: 31
      created_at: 1290070123000
    }
    {
      url: "http://jbbs.shitaraba.net/bbs/read.cgi/__computer/42710/1273802908/"
      title: "read.crx総合"
      res_count: 1000
      created_at: 1273802908000
    }
  ]
  expected2 = app.deep_copy(expected1)
  expected2.push {
    url: "http://jbbs.shitaraba.net/bbs/read.cgi/__computer/42710/1273732874/"
    title: "テストスレ"
    res_count: 413
    created_at: 1273732874000
  }
  expected2.push {
    url: "http://jbbs.shitaraba.net/bbs/read.cgi/__computer/42710/1273734819/"
    title: "スレスト"
    res_count: 1
    created_at: 1273734819000
  }
  @test {
    url: "http://jbbs.shitaraba.net/__computer/42710/"
    dat_url: "http://jbbs.shitaraba.net/__computer/42710/subject.txt"
    dat1
    expected1
    dat2
    expected2
  }
  return
