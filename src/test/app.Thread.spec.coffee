describe "app.Thread", ->
  cache = null
  cacheGetDeferred = null
  cachePutDeferred = null
  request = null
  httpRequestSendCallback = null
  getCachedResCountDeferred = null
  chServerMoveDetectDeferred = null

  beforeEach ->
    spyOn(app.Cache::, "get").andCallFake ->
      cache = @
      cacheGetDeferred = $.Deferred()
      cacheGetDeferred.promise()

    spyOn(app.Cache::, "put").andCallFake ->
      cache = @
      cachePutDeferred = $.Deferred()
      cachePutDeferred.promise()

    spyOn(app.HTTP.Request::, "send").andCallFake (callback) ->
      request = @
      httpRequestSendCallback = callback
      return

    spyOn(app.Board, "get_cached_res_count").andCallFake (url) ->
      getCachedResCountDeferred = $.Deferred()
      getCachedResCountDeferred.promise()

    spyOn(app.util, "ch_server_move_detect").andCallFake (url) ->
      chServerMoveDetectDeferred = $.Deferred()
      chServerMoveDetectDeferred.promise()

    spyOn(app.bookmark, "update_res_count")
    spyOn(app.bookmark, "update_expired")
    return

  # キャッシュなし状態でスレッド取得する場合のthread/cache/通信部のテスト
  # config.data
  test200 = (thread, config) ->
    deferred = $.Deferred()

    startTime = Date.now()

    threadGetPromise = thread.get()

    waitsFor ->
      cacheGetDeferred?

    runs ->
      cacheGetDeferred.reject()
      if app.url.tsld(config.data.url) in ["livedoor.jp", "machi.to"]
        expect(app.Board.get_cached_res_count).toHaveBeenCalled()
        getCachedResCountDeferred
          .resolve(res_count: config.data.expected.res.length)
      else
        expect(app.Board.get_cached_res_count).not.toHaveBeenCalled()
      return

    waitsFor ->
      request?

    runs ->
      response = new app.HTTP.Response(200, {}, config.data.dat)
      httpRequestSendCallback(response)

      expect(threadGetPromise.state()).toBe("resolved")
      expect(thread.message).toBeNull()
      expect(thread.title).toBe(config.data.expected.title)
      expect(thread.res).toEqual(config.data.expected.res)

      expect(app.Cache::put).toHaveBeenCalled()
      expect(cache.data).toBe(config.data.dat)
      expect(cache.last_updated).toBeGreaterThan(startTime - 1)
      expect(cache.last_updated).toBeLessThan(Date.now() + 1)
      expect(cache.last_modified).toBeNull()
      expect(cache.etag).toBeNull()
      expect(cache.res_length).toBe(config.data.expected.res.length)
      expect(cache.dat_size).toBeNull()

      deferred.resolve()
      return
    deferred.promise()

  # 存在しないスレを取得した時（200でエラーメッセージを返して来るタイプ用）
  # config.data
  testNotFoundType200 = (thread, config) ->
    deferred = $.Deferred()

    threadGetPromise = thread.get()

    waitsFor ->
      cacheGetDeferred?

    runs ->
      cacheGetDeferred.reject()
      if app.url.tsld(config.data.url) in ["livedoor.jp", "machi.to"]
        expect(app.Board.get_cached_res_count).toHaveBeenCalled()
        getCachedResCountDeferred.reject()
      else
        expect(app.Board.get_cached_res_count).not.toHaveBeenCalled()
      return

    waitsFor ->
      request?

    runs ->
      response = new app.HTTP.Response(200, {}, config.data.dat)
      httpRequestSendCallback(response)

      expect(threadGetPromise.state()).toBe("rejected")
      expect(thread.message).toBe("スレッドの読み込みに失敗しました。")
      expect(thread.title).toBeNull()
      expect(thread.res).toBeNull()

      expect(app.Cache::put).not.toHaveBeenCalled()
      expect(cache.data).toBeNull()
      expect(cache.last_updated).toBeNull()
      expect(cache.last_modified).toBeNull()
      expect(cache.etag).toBeNull()
      expect(cache.res_length).toBeNull()
      expect(cache.dat_size).toBeNull()

      deferred.resolve()
      return
    deferred.promise()

  # キャッシュ有り状態でスレッド取得時、更新が無かった場合
  # config.statusCode, config.data, config.data2
  test304 = (thread, config) ->
    deferred = $.Deferred()

    startTime = Date.now()

    cacheModified = startTime - 60 * 1000
    cacheUpdated = startTime - 30 * 1000
    cacheEtag = "dummyEtag#{cacheModified}"

    threadGetPromise = thread.get()

    waitsFor ->
      cacheGetDeferred?

    runs ->
      cache.data = config.data.dat
      cache.last_updated = cacheUpdated
      cache.last_modified = cacheModified
      cache.etag = cacheEtag
      cache.res_length = config.data.expected.res.length
      cache.dat_size = null
      cacheGetDeferred.resolve()

      if app.url.tsld(config.data.url) in ["livedoor.jp", "machi.to"]
        expect(app.Board.get_cached_res_count).toHaveBeenCalled()
        getCachedResCountDeferred
          .resolve(res_count: config.data.expected.res.length)
      else
        expect(app.Board.get_cached_res_count).not.toHaveBeenCalled()
      return

    waitsFor ->
      request?

    runs ->
      expect(request.url).toBe(config.data2.datURL)
      expect(request.headers["If-Modified-Since"])
        .toBe((new Date(cacheModified)).toUTCString())
      expect(request.headers["If-None-Match"]).toBe(cacheEtag)

      response = new app.HTTP.Response(config.statusCode, {}, "")
      httpRequestSendCallback(response)

      expect(threadGetPromise.state()).toBe("resolved")
      expect(thread.message).toBeNull()
      expect(thread.title).toBe(config.data.expected.title)
      expect(thread.res).toEqual(config.data.expected.res)

      expect(app.Cache::put).toHaveBeenCalled()
      expect(cache.data).toBe(config.data.dat)
      expect(cache.last_updated).toBeGreaterThan(startTime - 1)
      expect(cache.last_updated).toBeLessThan(Date.now() + 1)
      expect(cache.last_modified).toBe(cacheModified)
      expect(cache.etag).toBe(cacheEtag)
      expect(cache.res_length).toBe(config.data.expected.res.length)
      expect(cache.dat_size).toBeNull()

      deferred.resolve()
      return
    deferred.promise()

  # キャッシュ有り状態でスレッド取得時、更新が有った場合
  # config.delta, config.data, config.data2
  testUpdated = (thread, config) ->
    deferred = $.Deferred()

    startTime = Date.now()

    cacheModified = startTime - 60 * 1000
    cacheUpdated = startTime - 30 * 1000
    cacheEtag = "dummyEtag#{cacheModified}"

    dat2Modified = startTime - 10 * 1000
    dat2Etag = "dummyEtag#{dat2Modified}"

    threadGetPromise = thread.get()

    waitsFor ->
      cacheGetDeferred?

    runs ->
      cache.data = config.data.dat
      cache.last_updated = cacheUpdated
      cache.last_modified = cacheModified
      cache.etag = cacheEtag
      cache.res_length = config.data.expected.res.length
      cache.dat_size = null
      cacheGetDeferred.resolve()

      if app.url.tsld(config.data.url) in ["livedoor.jp", "machi.to"]
        expect(app.Board.get_cached_res_count).toHaveBeenCalled()
        getCachedResCountDeferred
          .resolve(res_count: config.data.expected.res.length)
      else
        expect(app.Board.get_cached_res_count).not.toHaveBeenCalled()
      return

    waitsFor ->
      request?

    runs ->
      expect(request.url).toBe(config.data2.datURL)
      expect(request.headers["If-Modified-Since"])
        .toBe((new Date(cacheModified)).toUTCString())
      expect(request.headers["If-None-Match"]).toBe(cacheEtag)

      response = new app.HTTP.Response(200, {
        "Last-Modified": dat2Modified
        "ETag": dat2Etag
      }, config.data2.dat)
      httpRequestSendCallback(response)

      expect(threadGetPromise.state()).toBe("resolved")
      expect(thread.message).toBeNull()
      expect(thread.title).toBe(config.data2.expected.title)
      expect(thread.res).toEqual(config.data2.expected.res)

      expect(app.Cache::put).toHaveBeenCalled()
      if config.delta
        expect(cache.data).toBe(config.data.dat + config.data2.dat)
      else
        expect(cache.data).toBe(config.data2.dat)
      expect(cache.last_updated).toBeGreaterThan(startTime - 1)
      expect(cache.last_updated).toBeLessThan(Date.now() + 1)
      expect(cache.last_modified).toBe(dat2Modified)
      expect(cache.etag).toBe(dat2Etag)
      expect(cache.res_length).toBe(config.data2.expected.res.length)
      expect(cache.dat_size).toBeNull()

      deferred.resolve()
      return
    deferred.promise()

  data = {}

  # 2ch
  data.ch =
    url: "http://__dummy.2ch.net/test/read.cgi/dummy/200/"
    datURL: "http://__dummy.2ch.net/dummy/dat/200.dat"
    dat: """
    ﾉtasukeruyo </b>忍法帖【Lv=10,xxxPT】<b> </b>◆0a./bc.def <b><><>2011/04/04(月) 10:19:46.92 ID:abcdEfGH0 BE:1234567890-2BP(1)<> テスト。 <br> http://qb5.2ch.net/test/read.cgi/operate/132452341234/1 <br> <hr><font color="blue">Monazilla/1.00 (V2C/2.5.1)</font> <>[test] テスト 123 [ﾃｽﾄ]
     </b>【東電 84.2 %】<b>  </b>◆0a./bc.def <b><>sage<>2011/04/04(月) 10:21:08.27 ID:abcdEfGH0<> てすとてすとテスト! <>
     </b>忍法帖【Lv=11,xxxPT】<b> <>sage<>2011/04/04(月) 10:24:46.33 ID:abc0DEFG1<> <a href="../test/read.cgi/operate/1234567890/1" target="_blank">&gt&gt1</a> <br> 乙 <br> てすとてすと試験てすと <>
    動け動けウゴウゴ２ちゃんねる<>sage<>2011/04/04(月) 10:25:17.27 ID:ABcdefgh0<> てすと、テスト <>
    動け動けウゴウゴ２ちゃんねる<><>2011/04/04(月) 10:25:51.88 ID:aBcdEfg+0<> てす <>

    """
    expected:
      title: "[test] テスト 123 [ﾃｽﾄ]"
      res: [
        {
          name: "ﾉtasukeruyo </b>忍法帖【Lv=10,xxxPT】<b> </b>◆0a./bc.def <b>"
          mail: ""
          message: ' テスト。 <br> http://qb5.2ch.net/test/read.cgi/operate/132452341234/1 <br> <hr><font color="blue">Monazilla/1.00 (V2C/2.5.1)</font> '
          other: "2011/04/04(月) 10:19:46.92 ID:abcdEfGH0 BE:1234567890-2BP(1)"
        }
        {
          name: " </b>【東電 84.2 %】<b>  </b>◆0a./bc.def <b>"
          mail: "sage"
          message: " てすとてすとテスト! "
          other: "2011/04/04(月) 10:21:08.27 ID:abcdEfGH0"
        }
        {
          name: " </b>忍法帖【Lv=11,xxxPT】<b> "
          mail: "sage"
          message: ' <a href="../test/read.cgi/operate/1234567890/1" target="_blank">&gt&gt1</a> <br> 乙 <br> てすとてすと試験てすと '
          other: "2011/04/04(月) 10:24:46.33 ID:abc0DEFG1"
        }
        {
          name: "動け動けウゴウゴ２ちゃんねる"
          mail: "sage"
          message: " てすと、テスト "
          other: "2011/04/04(月) 10:25:17.27 ID:ABcdefgh0"
        }
        {
          name: "動け動けウゴウゴ２ちゃんねる"
          mail: ""
          message: " てす "
          other: "2011/04/04(月) 10:25:51.88 ID:aBcdEfg+0"
        }
      ]

  # 2ch（更新テスト用データ）
  data.chUpdated = app.deep_copy(data.ch)
  data.chUpdated.dat += """
  774<><>2011/04/05(月) 00:00:00.00 ID:aaaaaaaaa<> test <>
  """
  data.chUpdated.expected.res.push(
    name: "774"
    mail: ""
    message: " test "
    other: "2011/04/05(月) 00:00:00.00 ID:aaaaaaaaa"
  )

  # 2ch（何らかの理由でデータが壊れた場合）
  data.chBroken =
    url: "http://__dummy.2ch.net/test/read.cgi/dummy/3526345446225/"
    datURL: "http://__dummy.2ch.net/dummy/dat/3526345446225.dat"
    dat: """
    偽*** ★<><>2011/10/21(金) 19:26:30.52 ID:???<> てすと　試験テスト <>***を追跡する #dummy
    </b> dummy <b><><>11/10/21(金) 20:49:40 ID:ehenfox<>62¥¥¥
    ぬふあ <br> <>twitter
    ***<><>2011/10/21(金) 20:50:00.66 ID:abcDeFgh<> よ <>
    """
    expected:
      title: "***を追跡する #dummy"
      res: [
        {
          name: "偽*** ★"
          mail: ""
          message: " てすと　試験テスト "
          other: "2011/10/21(金) 19:26:30.52 ID:???"
        }
        {
          name: "</b>データ破損<b>"
          mail: ""
          message: "データが破損しています"
          other: ""
        }
        {
          name: "</b>データ破損<b>"
          mail: ""
          message: "データが破損しています"
          other: ""
        }
        {
          name: "***"
          mail: ""
          message: " よ "
          other: "2011/10/21(金) 20:50:00.66 ID:abcDeFgh"
        }
      ]

  # 2ch（存在しないスレッド）
  data.ch404 =
    url: "http://__dummy.2ch.net/test/read.cgi/dummy/404/"
    datURL: "http://__dummy.2ch.net/dummy/dat/404.dat"
    dat: """
    <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
    <html><head>
    <title>404 Not Found</title>
    </head><body>
    <h1>Not Found</h1>
    <p>The requested URL /dummy/dat/404.dat was not found on this server.</p>
    <hr>
    <address>Apache/2.2.21 (Unix) mod_ssl/2.2.21 OpenSSL/0.9.8q PHP/5.3.8 mod_antiloris/0.4 Server at __dummy.2ch.net Port 80</address>
    </body></html>
    """

  # まちBBS
  data.machi =
    url: "http://__dummy.machi.to/bbs/read.cgi/dummy/511234524356/"
    datURL: "http://__dummy.machi.to/bbs/offlaw.cgi/dummy/511234524356/"
    dat: """
    1<>まちこさん<><>2007/06/10(日) 09:20:35 ID:aBC.DeFG<>テストテストテスト。<br><br>sage推奨<>【test】色々testスレ（トリップテストとか）【テスト】　７題目
    2<>◆</b>1a2BC3DeFg<b><><>2007/06/11(月) 22:33:18 ID:Ab0cdeFG<>あ　い　う　え　tesu<>
    5<>◆</b>abcd.EfGHI<b><>sage<>2007/06/13(水) 14:49:19 ID:aBcdEfgH<>あ　い　う　え　tesu３<>

    """
    expected:
      title: "【test】色々testスレ（トリップテストとか）【テスト】　７題目"
      res: [
        {
          name: "まちこさん"
          mail: ""
          message: "テストテストテスト。<br><br>sage推奨"
          other: "2007/06/10(日) 09:20:35 ID:aBC.DeFG"
        }
        {
          name: "◆</b>1a2BC3DeFg<b>"
          mail: ""
          message: "あ　い　う　え　tesu"
          other: "2007/06/11(月) 22:33:18 ID:Ab0cdeFG"
        }
        {
          name: "あぼーん"
          mail: "あぼーん"
          message: "あぼーん"
          other: "あぼーん"
        }
        {
          name: "あぼーん"
          mail: "あぼーん"
          message: "あぼーん"
          other: "あぼーん"
        }
        {
          name: "◆</b>abcd.EfGHI<b>"
          mail: "sage"
          message: "あ　い　う　え　tesu３"
          other: "2007/06/13(水) 14:49:19 ID:aBcdEfgH"
        }
      ]

  # まちBBS（差分取得テスト用データ）
  data.machiDelta =
    url: data.machi.url
    datURL: data.machi.datURL + (data.machi.expected.res.length + 1) + "-"
    dat: """
    6<>test<>sage<>2007/06/14(水) 14:49:19 ID:aBcdEfgH<>abcde<>

    """
    expected: app.deep_copy(data.machi.expected)

  data.machiDelta.expected.res.push(
    name: "test"
    mail: "sage"
    message: "abcde"
    other: "2007/06/14(水) 14:49:19 ID:aBcdEfgH"
  )

  # まちBBS（存在しないスレッド）
  data.machi404 =
    url: "http://__dummy.machi.to/bbs/read.cgi/dummy/404/"
    datURL: "http://__dummy.machi.to/bbs/offlaw.cgi/dummy/404/"
    dat: "<ERROR>スレッドを発見できません</ERROR>"

  # したらば
  data.jbbs =
    url: "http://jbbs.livedoor.jp/bbs/read.cgi/__dummy/42710/1310968239/"
    datURL: "http://jbbs.livedoor.jp/bbs/rawmode.cgi/__dummy/42710/1310968239/"
    dat: """
    1<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:50:39<>テスト<>削除レスとかの動作を確認するためのスレ<>???
    2<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:51:47<>テスト2<><>???
    3<>＜削除＞<>＜削除＞<>＜削除＞<>＜削除＞<><>
    4<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:53:07<><a href="/bbs/read.cgi/computer/42710/1310968239/3" target="_blank">&gt;&gt;3</a><br>削除<><>???
    7<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:54:08<><a href="/bbs/read.cgi/computer/42710/1310968239/5" target="_blank">&gt;&gt;5</a>, 6<br>透明削除<><>???
    8<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:55:04<><a href="/bbs/read.cgi/computer/42710/1310968239/9" target="_blank">&gt;&gt;9</a>, 10<br>透明削除<><>???

    """
    expected:
      title: "削除レスとかの動作を確認するためのスレ"
      res: [
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: "テスト"
          other: "2011/07/18(月) 14:50:39 ID:???"
        }
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: "テスト2"
          other: "2011/07/18(月) 14:51:47 ID:???"
        }
        {
          name: "＜削除＞"
          mail: "＜削除＞"
          message: "＜削除＞"
          other: "＜削除＞"
        }
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: '<a href="/bbs/read.cgi/computer/42710/1310968239/3" target="_blank">&gt;&gt;3</a><br>削除'
          other: "2011/07/18(月) 14:53:07 ID:???"
        }
        {
          name: "あぼーん"
          mail: "あぼーん"
          message: "あぼーん"
          other: "あぼーん"
        }
        {
          name: "あぼーん"
          mail: "あぼーん"
          message: "あぼーん"
          other: "あぼーん"
        }
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: '<a href="/bbs/read.cgi/computer/42710/1310968239/5" target="_blank">&gt;&gt;5</a>, 6<br>透明削除'
          other: "2011/07/18(月) 14:54:08 ID:???"
        }
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: '<a href="/bbs/read.cgi/computer/42710/1310968239/9" target="_blank">&gt;&gt;9</a>, 10<br>透明削除'
          other: "2011/07/18(月) 14:55:04 ID:???"
        }
      ]

  # したらば（差分取得テスト用データ）
  data.jbbsDelta =
    url: data.jbbs.url
    datURL: data.jbbs.datURL + (data.jbbs.expected.res.length + 1) + "-"
    dat: """
    9<>名無しさん<>sage<>2010/12/05(土) 22:57:40<>test<><>.aBCefGh

    """
    expected: app.deep_copy(data.jbbs.expected)

  data.jbbsDelta.expected.res.push(
    name: "名無しさん"
    mail: "sage"
    message: "test"
    other: "2010/12/05(土) 22:57:40 ID:.aBCefGh"
  )

  # したらば（存在しないスレッド）
  data.jbbs404 =
    url: "http://jbbs.livedoor.jp/bbs/read.cgi/__dummy/42710/404/"
    datURL: "http://jbbs.livedoor.jp/bbs/rawmode.cgi/__dummy/42710/404/"
    dat: ""

  # BBSPINK
  data.pink =
    url: "http://__dummy.bbspink.com/test/read.cgi/erobbs/23455435345543/"
    datURL: "http://__dummy.bbspink.com/erobbs/dat/23455435345543.dat"
    dat: """
    名無し編集部員<><>2008/03/22(土) 03:34:04 ID:aBcD0Ef1<> てすとてすとてすと <>レス削除練習用のスレ
    うふ～ん<>うふ～ん<>うふ～ん ID:DELETED<>うふ～ん<>うふ～ん<>
     </b>◆ABC/1/DEF. <b><><>2008/03/22(土) 03:53:57 ID:aB+C0Def<> てすと <>
    """
    expected:
      title: "レス削除練習用のスレ"
      res: [
        {
          name: "名無し編集部員"
          mail: ""
          message: " てすとてすとてすと "
          other: "2008/03/22(土) 03:34:04 ID:aBcD0Ef1"
        }
        {
          name: "うふ～ん"
          mail: "うふ～ん"
          message: "うふ～ん"
          other: "うふ～ん ID:DELETED"
        }
        {
          name: " </b>◆ABC/1/DEF. <b>"
          mail: ""
          message: " てすと "
          other: "2008/03/22(土) 03:53:57 ID:aB+C0Def"
        }
      ]

  describe "実例テスト: スレッド取得（初回, 成功）", ->
    it "2ch", ->
      test200(new app.Thread(data.ch.url), data: data.ch)
      return

    it "2ch（破損）", ->
      test200(new app.Thread(data.chBroken.url), data: data.chBroken)
      return

    it "したらば", ->
      test200(new app.Thread(data.jbbs.url), data: data.jbbs)
      return

    it "まちBBS", ->
      test200(new app.Thread(data.machi.url), data: data.machi)
      return

    it "BBSPINK", ->
      test200(new app.Thread(data.pink.url), data: data.pink)
      return
    return

  describe "実例テスト: スレッド取得（失敗, 存在しないURL）", ->
    it "2ch", ->
      thread = new app.Thread(data.ch404.url)
      threadGetPromise = thread.get()

      waitsFor ->
        cacheGetDeferred?

      runs ->
        cacheGetDeferred.reject()
        expect(app.Board.get_cached_res_count).not.toHaveBeenCalled()
        return

      waitsFor ->
        request?

      runs ->
        response = new app.HTTP.Response(404, {}, data.ch404.dat)
        httpRequestSendCallback(response)
        return

      waitsFor ->
        chServerMoveDetectDeferred?

      runs ->
        expect(app.util.ch_server_move_detect)
          .toHaveBeenCalledWith(app.url.thread_to_board(data.ch404.url))

        chServerMoveDetectDeferred.reject()

        expect(threadGetPromise.state()).toBe("rejected")
        expect(thread.message).toBe("スレッドの読み込みに失敗しました。")
        expect(thread.title).toBeNull()
        expect(thread.res).toBeNull()

        expect(app.Cache::put).not.toHaveBeenCalled()
        expect(cache.data).toBeNull()
        expect(cache.last_updated).toBeNull()
        expect(cache.last_modified).toBeNull()
        expect(cache.etag).toBeNull()
        expect(cache.res_length).toBeNull()
        expect(cache.dat_size).toBeNull()
        return
      return

    it "したらば", ->
      thread = new app.Thread(data.jbbs404.url)
      testNotFoundType200(thread, data: data.jbbs404)
      return

    it "まちBBS", ->
      thread = new app.Thread(data.machi404.url)
      testNotFoundType200(thread, data: data.machi404)
      return
    return

  describe "実例テスト: スレッド取得（キャッシュ有り、更新無し時）", ->
    it "2ch", ->
      thread = new app.Thread(data.ch.url)
      test304(thread, statusCode: 304, data: data.ch, data2: data.chUpdated)
      return

    it "したらば", ->
      thread = new app.Thread(data.jbbs.url)
      test304(thread, statusCode: 200, data: data.jbbs, data2: data.jbbsDelta)
      return

    it "まちBBS", ->
      thread = new app.Thread(data.machi.url)
      test304(thread, statusCode: 304, data: data.machi, data2: data.machiDelta)
      return
    return

  describe "実例テスト: スレッド取得（キャッシュ有り、更新時）", ->
    it "2ch", ->
      thread = new app.Thread(data.ch.url)
      testUpdated(thread, delta: false, data: data.ch, data2: data.chUpdated)
      return

    it "したらば", ->
      thread = new app.Thread(data.jbbs.url)
      testUpdated(thread, delta: true, data: data.jbbs, data2: data.jbbsDelta)
      return

    it "まちBBS", ->
      thread = new app.Thread(data.machi.url)
      testUpdated(thread, delta: true, data: data.machi, data2: data.machiDelta)
      return
    return

  describe "実例テスト: 初回取得→更新なし→更新有り", ->
    _dateSeed = Date.now() - 1000 * 60 * 60 * 24

    beforeEach ->
      spyOn(Date, "now").andCallFake ->
        _dateSeed += 1000 * 60
        _dateSeed
      return

    it "2ch", ->
      thread = new app.Thread(data.ch.url)

      promise = (
        test200(thread, data: data.ch)
          .pipe ->
            test304(thread, {
              statusCode: 304
              data: data.ch
              data2: data.chUpdated
            })
          .pipe ->
            testUpdated(thread, {
              delta: false
              data: data.ch
              data2: data.chUpdated
            })
      )

      waitsFor ->
        promise.state() is "resolved"
      return

    it "したらば", ->
      thread = new app.Thread(data.jbbs.url)

      promise = (
        test200(thread, data: data.jbbs)
          .pipe ->
            test304(thread, {
              statusCode: 200
              data: data.jbbs
              data2: data.jbbsDelta
            })
          .pipe ->
            testUpdated(thread, {
              delta: true
              data: data.jbbs
              data2: data.jbbsDelta
            })
      )

      waitsFor ->
        promise.state() is "resolved"
      return

    it "まちBBS", ->
      thread = new app.Thread(data.machi.url)

      promise = (
        test200(thread, data: data.machi)
          .pipe ->
            test304(thread, {
              statusCode: 304
              data: data.machi
              data2: data.machiDelta
            })
          .pipe ->
            testUpdated(thread, {
              delta: true
              data: data.machi
              data2: data.machiDelta
            })
      )

      waitsFor ->
        promise.state() is "resolved"
      return
    return

  describe "スレッド取得時", ->
    it "::get直後にキャッシュ取得を行う", ->
      thread = new app.Thread(data.ch.url)

      expect(app.Cache::get).not.toHaveBeenCalled()

      thread.get()

      expect(app.Cache::get).toHaveBeenCalled()
      return

    it "キャッシュ取得が完了した後、通信を開始する", ->
      new app.Thread(data.ch.url).get()

      expect(app.HTTP.Request::send).not.toHaveBeenCalled()

      cacheGetDeferred.reject()

      expect(app.HTTP.Request::send).toHaveBeenCalled()
      expect(request.preventCache).toBeTruthy()
      expect(request.url).toBe(data.ch.datURL)
      expect(request.mimeType).toBe("text/plain; charset=Shift_JIS")
      expect(request.headers).toEqual({})
      return

    it "通信完了後、パース処理等を行いpromiseを更新する", ->
      promise = new app.Thread(data.ch.url).get()
      cacheGetDeferred.reject()

      expect(promise.state()).toBe("pending")

      response = new app.HTTP.Response(200, {}, data.ch.dat)
      httpRequestSendCallback(response)

      expect(promise.state()).toBe("resolved")
      return
    return

  describe "通信成功時", ->
    thread = null

    beforeEach ->
      thread = new app.Thread(data.ch.url)
      thread.get()
      cacheGetDeferred.reject()
      response = new app.HTTP.Response(200, {}, data.ch.dat)
      httpRequestSendCallback(response)
      return

    it "プロパティを更新する", ->
      expect(thread.title).toBe(data.ch.expected.title)
      expect(thread.res).toEqual(data.ch.expected.res)
      expect(thread.message).toBeNull()
      return

    it "キャッシュを更新する", ->
      expect(app.Cache::put).toHaveBeenCalled()
      expect(cache.data).toBe(data.ch.dat)
      expect(cache.last_modified).toBeNull()
      expect(cache.last_updated).toBeCloseTo(Date.now(), 1000)
      expect(cache.etag).toBeNull()
      expect(cache.res_length).toBe(data.ch.expected.res.length)
      expect(cache.dat_size).toBeNull()
      return

    it "ブックマークのレス数を更新する", ->
      expect(app.bookmark.update_res_count).toHaveBeenCalledWith(
        data.ch.url
        data.ch.expected.res.length
      )
      return
    return

  describe "キャッシュが取得出来た場合", ->
    thread = null
    threadGetPromise = null

    beforeEach ->
      thread = new app.Thread(data.ch.url)
      threadGetPromise = thread.get()

      cache.data = data.ch.dat
      cache.last_updated = Date.now() - 1000 * 60 * 5
      cache.last_modified = Date.now() - 1000 * 60 * 10
      cache.etag = "dummyetag"
      cache.res_length = data.ch.expected.res.length
      return

    it "キャッシュが更新されたばかりの場合、通信を行わない", ->
      cache.last_updated = Date.now() - 1000

      cacheGetDeferred.resolve()

      expect(app.HTTP.Request::send).not.toHaveBeenCalled()
      return

    it "通信前にキャッシュをパースして、notifyで通達する", ->
      onProgress = jasmine.createSpy("onProgress")
      threadGetPromise.progress(onProgress)

      cacheGetDeferred.resolve()

      waitsFor ->
        onProgress.wasCalled

      runs ->
        expect(onProgress).toHaveBeenCalled()
        expect(thread.title).toBe(data.ch.expected.title)
        expect(thread.res).toEqual(data.ch.expected.res)
        expect(thread.message).toBeNull()
        return
      return

    it "last_modified/etagが取得出来た場合、通信時に使用する", ->
      cacheGetDeferred.resolve()

      expect(request.headers["If-Modified-Since"])
        .toBe(new Date(cache.last_modified).toUTCString())
      expect(request.headers["If-None-Match"]).toBe(cache.etag)
      return

    it "したらばのデータ取得時に差分取得を試みる", ->
      new app.Thread(data.jbbs.url).get()

      cache.data = data.jbbs.dat
      cache.res_length = data.jbbs.expected.res.length
      cacheGetDeferred.resolve()

      expect(request.url)
        .toBe(data.jbbs.datURL + (data.jbbs.expected.res.length + 1) + "-")
      return

    it "まちBBSのデータ取得時に差分取得を試みる", ->
      new app.Thread(data.machi.url).get()

      cache.data = data.machi.dat
      cache.res_length = data.machi.expected.res.length
      cacheGetDeferred.resolve()

      expect(request.url)
        .toBe(data.machi.datURL + (data.machi.expected.res.length + 1) + "-")
      return

    it "304だった場合、キャッシュの更新時刻のみ変更する", ->
      storedLastUpdated = cache.last_updated
      storedLastModified = cache.last_modified

      cacheGetDeferred.resolve()
      httpRequestSendCallback(new app.HTTP.Response(304))

      expect(app.Cache::put).toHaveBeenCalled()
      expect(cache.data).toBe(data.ch.dat)
      expect(cache.last_updated).toBeGreaterThan(storedLastUpdated)
      expect(cache.last_modified).toBe(storedLastModified)
      expect(cache.etag).toBe("dummyetag")
      expect(cache.res_length).toBe(data.ch.expected.res.length)
      return
    return

  describe "通信失敗時", ->
    thread = null
    threadGetPromise = null

    beforeEach ->
      thread = new app.Thread(data.ch.url)
      threadGetPromise = thread.get()
      cacheGetDeferred.reject()
      httpRequestSendCallback(new app.HTTP.Response(404, {}, "not found"))
      chServerMoveDetectDeferred.reject()
      return

    it "2chの場合、移転チェックを行う", ->
      expect(app.util.ch_server_move_detect)
        .toHaveBeenCalledWith(app.url.thread_to_board(data.ch.url))
      return

    it "キャッシュを更新しない", ->
      expect(app.Cache::put).not.toHaveBeenCalled()
      return

    it "promiseをrejectする", ->
      expect(threadGetPromise.state()).toBe("rejected")
      return

    it ".messageを更新する", ->
      expect(thread.message).toBe("スレッドの読み込みに失敗しました。")
      return
    return

  describe "したらば最新レス削除対策", ->
    it "スレ覧の値より少ないレス数だった場合、最新レスが削除されたとみなす", ->
      expected = app.deep_copy(data.jbbs.expected.res)
      expected.push(
        name: "あぼーん"
        mail: "あぼーん"
        message: "あぼーん"
        other: "あぼーん"
      )

      thread = new app.Thread(data.jbbs.url)
      promise = thread.get()
      cacheGetDeferred.reject()
      httpRequestSendCallback(new app.HTTP.Response(200, {}, data.jbbs.dat))

      app.defer ->
        getCachedResCountDeferred.resolve(res_count: expected.length)
        return

      waitsFor ->
        promise.state() is "resolved"

      runs ->
        expect(thread.res).toEqual(expected)
        return
      return
    return

  describe "まちBBS最新レス削除対策", ->
    it "スレ覧の値より少ないレス数だった場合、最新レスが削除されたとみなす", ->
      expected = app.deep_copy(data.machi.expected.res)
      expected.push(
        name: "あぼーん"
        mail: "あぼーん"
        message: "あぼーん"
        other: "あぼーん"
      )

      thread = new app.Thread(data.machi.url)
      promise = thread.get()
      cacheGetDeferred.reject()
      httpRequestSendCallback(new app.HTTP.Response(200, {}, data.machi.dat))

      app.defer ->
        getCachedResCountDeferred.resolve(res_count: expected.length)
        return

      waitsFor ->
        promise.state() is "resolved"

      runs ->
        expect(thread.res).toEqual(expected)
        return
      return
    return

  describe ".parse", ->
    it "2chのDATをパース出来る", ->
      expect(app.Thread.parse(data.ch.url, data.ch.dat))
        .toEqual(data.ch.expected)
      return

    it "まちBBSのデータをパース出来る", ->
      expect(app.Thread.parse(data.machi.url, data.machi.dat))
        .toEqual(data.machi.expected)
      return

    it "したらばのデータをパース出来る", ->
      expect(app.Thread.parse(data.jbbs.url, data.jbbs.dat))
        .toEqual(data.jbbs.expected)
      return

    it "BBSPINKのデータをパース出来る", ->
      expect(app.Thread.parse(data.pink.url, data.pink.dat))
        .toEqual(data.pink.expected)
      return

    it "DATの破損部分はエラーメッセージで代替する", ->
      expect(app.Thread.parse(data.chBroken.url, data.chBroken.dat))
        .toEqual(data.chBroken.expected)
      return

    it "全ての行が破損データだった場合、nullを返す", ->
      # 2chで一部のスレが302 -> 200で404.htmlが返される挙動になる事への対策
      url = "http://hibari.2ch.net/test/read.cgi/pc/123/"
      html = """
      <html>
        <head><title>test</title></head>
        <body>
          Error
        </body>
      </html>
      """

      expect(app.Thread.parse(url, html)).toBeNull()
      return
    return
  return
