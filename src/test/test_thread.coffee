module "Thread::get",
  setup: ->
    @ch_url = "http://__mockjax.2ch.net/test/read.cgi/dummy/200/"
    @ch_dat_url = "http://__mockjax.2ch.net/dummy/dat/200.dat"
    @ch_dat = """
    ﾉtasukeruyo </b>忍法帖【Lv=10,xxxPT】<b> </b>◆0a./bc.def <b><><>2011/04/04(月) 10:19:46.92 ID:abcdEfGH0 BE:1234567890-2BP(1)<> テスト。 <br> http://qb5.2ch.net/test/read.cgi/operate/132452341234/1 <br> <hr><font color="blue">Monazilla/1.00 (V2C/2.5.1)</font> <>[test] テスト 123 [ﾃｽﾄ]
     </b>【東電 84.2 %】<b>  </b>◆0a./bc.def <b><>sage<>2011/04/04(月) 10:21:08.27 ID:abcdEfGH0<> てすとてすとテスト! <>
     </b>忍法帖【Lv=11,xxxPT】<b> <>sage<>2011/04/04(月) 10:24:46.33 ID:abc0DEFG1<> <a href="../test/read.cgi/operate/1234567890/1" target="_blank">&gt&gt1</a> <br> 乙 <br> てすとてすと試験てすと <>
    動け動けウゴウゴ２ちゃんねる<>sage<>2011/04/04(月) 10:25:17.27 ID:ABcdefgh0<> てすと、テスト <>
    動け動けウゴウゴ２ちゃんねる<><>2011/04/04(月) 10:25:51.88 ID:aBcdEfg+0<> てす <>

    """
    @ch_expected =
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

    @ch_broken_url = "http://__mockjax.2ch.net/test/read.cgi/dummy/3526345446225/"
    @ch_broken_dat_url = "http://__mockjax.2ch.net/dummy/dat/3526345446225.dat"
    @ch_broken_dat = """
      偽*** ★<><>2011/10/21(金) 19:26:30.52 ID:???<> てすと　試験テスト <>***を追跡する #dummy
      </b> dummy <b><><>11/10/21(金) 20:49:40 ID:ehenfox<>62¥¥¥
      ぬふあ <br> <>twitter
      ***<><>2011/10/21(金) 20:50:00.66 ID:abcDeFgh<> よ <>
    """
    @ch_broken_expected =
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

    @machi_url = "http://__mockjax.machi.to/bbs/read.cgi/dummy/511234524356/"
    @machi_dat_url = "http://__mockjax.machi.to/bbs/offlaw.cgi/dummy/511234524356/"
    @machi_dat = """
      1<>まちこさん<><>2007/06/10(日) 09:20:35 ID:aBC.DeFG<>テストテストテスト。<br><br>sage推奨<>【test】色々testスレ（トリップテストとか）【テスト】　７題目
      2<>◆</b>1a2BC3DeFg<b><><>2007/06/11(月) 22:33:18 ID:Ab0cdeFG<>あ　い　う　え　tesu<>
      5<>◆</b>abcd.EfGHI<b><>sage<>2007/06/13(水) 14:49:19 ID:aBcdEfgH<>あ　い　う　え　tesu３<>

    """
    @machi_expected =
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

    @jbbs_url = "http://jbbs.livedoor.jp/bbs/read.cgi/__mockjax/42710/1290070091/"
    @jbbs_dat_url = "http://jbbs.livedoor.jp/bbs/rawmode.cgi/__mockjax/42710/1290070091/"
    @jbbs_dat = """
      1<><font color=#FF0000>awef★</font><><>2010/11/18(木) 17:48:11<>read.crxについての質問・要望・不具合報告等を気楽に書き込んで下さい<br><br>インストールはこちらから<br>ttps://chrome.google.com/extensions/detail/hhjpdicibjffnpggdiecaimdgdghainl<br>関連文章<br>ttp://wiki.livedoor.jp/awef/d/read.crx<br>UserVoice<br>ttp://readcrx.uservoice.com/<br>前スレ<br>ttp://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/<br><br>既出の要望・バグ等は全てUserVoiceで管理します<br>直接UserVoiceに投稿しちゃっても構いません<>read.crx総合 part2<>???
      2<>名無しさん<><>2010/12/03(金) 02:50:42<>試験用削除<><>ABCD0eFg
      5<>名無しさん<>sage<>2010/12/04(土) 22:57:40<><a href="/bbs/read.cgi/computer/42710/1290070091/2" target="_blank">&gt&gt2</a><br>少なくとも、今のブックマーク表示は、他の板とそれ程区別する必要は無いと思ってます<br><br><a href="/bbs/read.cgi/computer/42710/1290070091/4" target="_blank">&gt&gt4</a><br>サッとプロトコル見てみましたけど、多分無理っすね<br>こちら側も鯖立てないとムリっぽいし<><>.aBCefGh

    """
    @jbbs_expected =
      title: "read.crx総合 part2"
      res: [
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: "read.crxについての質問・要望・不具合報告等を気楽に書き込んで下さい<br><br>インストールはこちらから<br>ttps://chrome.google.com/extensions/detail/hhjpdicibjffnpggdiecaimdgdghainl<br>関連文章<br>ttp://wiki.livedoor.jp/awef/d/read.crx<br>UserVoice<br>ttp://readcrx.uservoice.com/<br>前スレ<br>ttp://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/<br><br>既出の要望・バグ等は全てUserVoiceで管理します<br>直接UserVoiceに投稿しちゃっても構いません"
          other: "2010/11/18(木) 17:48:11 ID:???"
        }
        {
          name: "名無しさん"
          mail: ""
          message: "試験用削除"
          other: "2010/12/03(金) 02:50:42 ID:ABCD0eFg"
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
          name: "名無しさん"
          mail: "sage"
          message: '<a href="/bbs/read.cgi/computer/42710/1290070091/2" target="_blank">&gt&gt2</a><br>少なくとも、今のブックマーク表示は、他の板とそれ程区別する必要は無いと思ってます<br><br><a href="/bbs/read.cgi/computer/42710/1290070091/4" target="_blank">&gt&gt4</a><br>サッとプロトコル見てみましたけど、多分無理っすね<br>こちら側も鯖立てないとムリっぽいし'
          other: "2010/12/04(土) 22:57:40 ID:.aBCefGh"
        }
      ]

    @jbbs_deleted_url = "http://jbbs.livedoor.jp/bbs/read.cgi/__mockjax/42710/1310968239/"
    @jbbs_deleted_dat_url = "http://jbbs.livedoor.jp/bbs/rawmode.cgi/__mockjax/42710/1310968239/"
    @jbbs_deleted_dat = """
      1<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:50:39<>テスト<>削除レスとかの動作を確認するためのスレ<>???
      2<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:51:47<>テスト2<><>???
      3<>＜削除＞<>＜削除＞<>＜削除＞<>＜削除＞<><>
      4<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:53:07<><a href="/bbs/read.cgi/computer/42710/1310968239/3" target="_blank">&gt;&gt;3</a><br>削除<><>???
      6<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:54:08<><a href="/bbs/read.cgi/computer/42710/1310968239/5" target="_blank">&gt;&gt;5</a><br>透明削除<><>???
      7<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:55:04<><a href="/bbs/read.cgi/computer/42710/1310968239/8" target="_blank">&gt;&gt;8</a>, 9<br>透明削除<><>???
    """
    @jbbs_deleted_expected =
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
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: '<a href="/bbs/read.cgi/computer/42710/1310968239/5" target="_blank">&gt;&gt;5</a><br>透明削除'
          other: "2011/07/18(月) 14:54:08 ID:???"
        }
        {
          name: "<font color=#FF0000>awef★</font>"
          mail: ""
          message: '<a href="/bbs/read.cgi/computer/42710/1310968239/8" target="_blank">&gt;&gt;8</a>, 9<br>透明削除'
          other: "2011/07/18(月) 14:55:04 ID:???"
        }
      ]

    @pink_url = "http://__mockjax.bbspink.com/test/read.cgi/erobbs/23455435345543/"
    @pink_dat_url = "http://__mockjax.bbspink.com/erobbs/dat/23455435345543.dat"
    @pink_dat = """
      名無し編集部員<><>2008/03/22(土) 03:34:04 ID:aBcD0Ef1<> てすとてすとてすと <>レス削除練習用のスレ
      うふ～ん<>うふ～ん<>うふ～ん ID:DELETED<>うふ～ん<>うふ～ん<>
       </b>◆ABC/1/DEF. <b><><>2008/03/22(土) 03:53:57 ID:aB+C0Def<> てすと <>
    """
    @pink_expected =
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

    @test_200 = (config) ->
      $.mockjax
        url: config.dat_url
        status: 200
        headers:
          etag: null
        responseText: config.dat
        response: ->
          QUnit.step(2)
          return

      app.module null, ["cache"], (Cache) =>
        new Cache(config.dat_url).delete().done =>
          QUnit.step(1)
          before = Date.now()

          thread = new app.Thread(config.url)
          thread.get().done =>
            QUnit.step(3)
            strictEqual(thread.title, config.thread_expected.title)
            deepEqual(thread.res, config.thread_expected.res)
            strictEqual(thread.message, null)

          thread._cachePut.progress (status) =>
            QUnit.step(4)
            strictEqual(status, "done", "cache.put()")
            cache = new Cache(config.dat_url)
            cache.get().done =>
              QUnit.step(5)
              strictEqual(cache.data, config.dat, "cache.data")
              ok(before < cache.last_updated < Date.now(), "cache.last_updated")
              strictEqual(cache.last_modified, null, "cache.last_modified")
              strictEqual(cache.etag, null, "cache.etag")
              strictEqual(cache.res_length, config.thread_expected.res.length, "cache.res_length")
              strictEqual(cache.dat_size, null, "cache.dat_size")
              start()
              return
            return
          return
      return

    #正常取得 -> 更新なし -> 更新有り
    @test_update = (config) ->
      app.module null, ["cache"], (Cache) ->
        dummy =
          etag: null
          last_modified: null
          update: ->
            @etag = Date.now().toString(36) + "-" + Date.now().toString(36)
            @last_modified = (new Date()).toUTCString()
            return

        thread = new app.Thread(config.url)
        before_1st_get = null
        before_2nd_get = null
        before_3rd_get = null

        #初回取得準備
        $.Deferred (d) ->
          QUnit.step(1)

          dummy.update()

          $.mockjax
            url: config.dat_url
            status: 200
            headers:
              "ETag": dummy.etag
              "Last-Modified": dummy.last_modified
            responseText: config.dat
            response: (ajax_settings) ->
              QUnit.step(3)
              deepEqual(ajax_settings.headers, {})
              return

          new Cache(config.dat_url).delete().done ->
            d.resolve()
            return
        #初回取得
        .pipe -> $.Deferred (d) ->
          QUnit.step(2)

          before_1st_get = Date.now()

          thread.get().done ->
            QUnit.step(4)
            strictEqual(thread.title, config.thread_expected.title)
            deepEqual(thread.res, config.thread_expected.res)
            strictEqual(thread.message, null)
            return

          run = false
          thread._cachePut.progress (status) ->
            return if run
            run = true

            QUnit.step(5)

            strictEqual(status, "done", "cache.put()")
            cache = new Cache(config.dat_url)
            cache.get().done =>
              QUnit.step(6)
              strictEqual(cache.data, config.dat, "cache.data")
              ok(before_1st_get < cache.last_updated < Date.now(), "cache.last_updated")
              strictEqual(cache.last_modified, Date.parse(dummy.last_modified), "cache.last_modified")
              strictEqual(cache.etag, dummy.etag, "cache.etag")
              strictEqual(cache.res_length, config.thread_expected.res.length, "cache.res_length")
              strictEqual(cache.dat_size, null, "cache.dat_size")
              d.resolve()
              return
            return
          return
        #2回目取得（更新無し）準備
        .pipe -> $.Deferred (d) ->
          QUnit.step(7)

          $.mockjaxClear()
          $.mockjax
            url: config.delta_dat_url
            status: 304
            headers:
              "ETag": dummy.etag
              "Last-Modified": dummy.last_modified
            responseText: ""
            response: (ajax_settings) ->
              QUnit.step(9)
              deepEqual(
                ajax_settings.headers
                {
                  "If-Modified-Since": dummy.last_modified
                  "If-None-Match": dummy.etag
                }
              )
              return
          d.resolve()
          return
        #過剰リロード防止機構回避
        .pipe -> $.Deferred (d) ->
          setTimeout(d.resolve, 3500)
          return
        #2回目取得
        .pipe -> $.Deferred (d) ->
          QUnit.step(8)
          before_2nd_get = Date.now()

          thread.get().done ->
            QUnit.step(10)
            strictEqual(thread.title, config.thread_expected.title)
            deepEqual(thread.res, config.thread_expected.res)
            strictEqual(thread.message, null)
            return

          run = 0
          thread._cachePut.progress (status) ->
            return if ++run isnt 2 #直前のnotifyの分まで呼ばれてしまうので、その対策

            QUnit.step(11)

            strictEqual(status, "done", "cache.put()")
            cache = new Cache(config.dat_url)
            cache.get().done ->
              QUnit.step(12)
              strictEqual(cache.data, config.dat, "cache.data")
              ok(before_2nd_get < cache.last_updated < Date.now(), "cache.last_updated")
              strictEqual(cache.last_modified, Date.parse(dummy.last_modified), "cache.last_modified")
              strictEqual(cache.etag, dummy.etag, "cache.etag")
              strictEqual(cache.res_length, config.thread_expected.res.length, "cache.res_length")
              strictEqual(cache.dat_size, null, "cache.dat_size")
              d.resolve()
              return
            return
          return
        #3回目取得（更新）準備
        .pipe -> $.Deferred (d) ->
          QUnit.step(13)

          $.mockjaxClear()
          old_dummy =
            etag: dummy.etag
            last_modified: dummy.last_modified
          dummy.update()
          $.mockjax
            url: config.delta_dat_url
            status: config.delta_status
            headers:
              "ETag": dummy.etag
              "Last-Modified": dummy.last_modified
            responseText: config.delta_dat
            response: (ajax_settings) ->
              QUnit.step(15)
              deepEqual(
                ajax_settings.headers
                {
                  "If-Modified-Since": old_dummy.last_modified
                  "If-None-Match": old_dummy.etag
                }
              )
              return
          d.resolve()
          return

        #過剰リロード防止機構回避
        .pipe -> $.Deferred (d) ->
          setTimeout(d.resolve, 3500)
          return
        #3回目取得
        .pipe -> $.Deferred (d) ->
          QUnit.step(14)
          before_3rd_get = Date.now()

          thread.get().done ->
            QUnit.step(16)
            strictEqual(thread.title, config.thread_expected.title)
            deepEqual(thread.res, config.thread_expected.res.concat(config.delta_res))
            strictEqual(thread.message, null)
            return

          run = 0
          thread._cachePut.progress (status) ->
            return if ++run isnt 2 #直前のnotifyの分まで呼ばれてしまうので、その対策

            QUnit.step(17)

            strictEqual(status, "done", "cache.put()")
            cache = new Cache(config.dat_url)
            cache.get().done ->
              QUnit.step(18)
              strictEqual(cache.data, config.last_dat, "cache.data")
              ok(before_3rd_get < cache.last_updated < Date.now(), "cache.last_updated")
              strictEqual(cache.last_modified, Date.parse(dummy.last_modified), "cache.last_modified")
              strictEqual(cache.etag, dummy.etag, "cache.etag")
              strictEqual(cache.res_length, config.thread_expected.res.length + config.delta_res.length, "cache.res_length")
              strictEqual(cache.dat_size, null, "cache.dat_size")
              d.resolve()
              return
            return
          return

        .always(start)
        return
      return

    #存在しないスレを取得しようとした時(まちBBS/したらば用)
    @test_machi_jbbs_none = (config) ->
      $.mockjax
        url: config.dat_url
        status: 200
        responseText: config.dat
        response: ->
          QUnit.step(2)
          return

      app.module null, ["cache"], (Cache) =>
        new Cache(config.dat_url).delete().done =>
          QUnit.step(1)

          thread = new app.Thread(config.url)
          thread.get().fail =>
            QUnit.step(3)
            strictEqual(thread.title, null, "thread.title")
            strictEqual(thread.res, null, "thread.res")
            strictEqual(thread.message, "スレッドの読み込みに失敗しました。", "thread.message")
            start()
            return

          thread._cachePut.progress (status) =>
            QUnit.step(4)
            strictEqual(status, "unexecuted", "cache.put()")
            cache = new Cache(config.dat_url)
            cache.get().fail =>
              QUnit.step(5)
              return
            return
          return
      return

    return

  teardown: $.mockjaxClear

asyncTest "2chのスレを取得出来る", 15, ->
  @test_200
    url: @ch_url
    dat_url: @ch_dat_url
    dat: @ch_dat
    thread_expected: @ch_expected
  return

asyncTest "2chのスレの取得/更新テスト", 51, ->
  delta_dat = @ch_dat + """
    動け動けウゴウゴ２ちゃんねる<><>2011/04/04(月) 10:55:00.00 ID:aaccrrr3<> test <>

  """

  @test_update
    url: @ch_url
    dat_url: @ch_dat_url
    dat: @ch_dat
    thread_expected: @ch_expected
    delta_dat_url: @ch_dat_url
    delta_status: 200
    delta_dat: delta_dat
    delta_res: [
      {
        name: "動け動けウゴウゴ２ちゃんねる"
        mail: ""
        message: " test "
        other: "2011/04/04(月) 10:55:00.00 ID:aaccrrr3"
      }
    ]
    last_dat: delta_dat
  return

asyncTest "2chの存在しないスレを取得しようとした場合", 10, ->
  dat_url = "http://__mockjax.2ch.net/dummy/dat/404.dat"

  $.mockjax
    url: dat_url
    status: 404
    headers:
      etag: null
    responseText: """
      <!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
      <html><head>
      <title>404 Not Found</title>
      </head><body>
      <h1>Not Found</h1>
      <p>The requested URL /dummy/dat/404.dat was not found on this server.</p>
      <hr>
      <address>Apache/2.2.21 (Unix) mod_ssl/2.2.21 OpenSSL/0.9.8q PHP/5.3.8 mod_antiloris/0.4 Server at __mockjax.2ch.net Port 80</address>
      </body></html>
    """
    response: ->
      QUnit.step(2)
      return

  #DAT取得失敗時、鯖移転の検出処理が走る
  $.mockjax
    url: "http://__mockjax\.2ch\.net/dummy/"
    response: ->
      QUnit.step(5)
      return

  app.module null, ["cache"], (Cache) =>
    new Cache(dat_url).delete().done =>
      QUnit.step(1)

      thread = new app.Thread("http://__mockjax.2ch.net/test/read.cgi/dummy/404/")
      thread.get().fail =>
        QUnit.step(6)
        strictEqual(thread.title, null)
        deepEqual(thread.res, null)
        strictEqual(thread.message, "スレッドの読み込みに失敗しました。")
        start()
        return

      thread._cachePut.progress (status) =>
        QUnit.step(3)
        strictEqual(status, "unexecuted", "cache.put()")
        cache = new Cache(dat_url)
        cache.get().fail =>
          QUnit.step(4)
          return
        return
      return
  return

asyncTest "2chのDATの破損部分は、破損メッセージで代替する", 15, ->
  @test_200
    url: @ch_broken_url
    dat_url: @ch_broken_dat_url
    dat: @ch_broken_dat
    thread_expected: @ch_broken_expected
  return

asyncTest "まちBBSのスレを取得出来る", 15, ->
  @test_200
    url: @machi_url
    dat_url: @machi_dat_url
    dat: @machi_dat
    thread_expected: @machi_expected
  return

asyncTest "まちBBSのスレの取得/更新テスト", 51, ->
  delta_dat = """
    6<>test<>sage<>2007/06/14(水) 14:49:19 ID:aBcdEfgH<>abcde<>

  """
  @test_update
    url: @machi_url
    dat_url: @machi_dat_url
    dat: @machi_dat
    thread_expected: @machi_expected
    delta_dat_url: @machi_dat_url + (@machi_expected.res.length + 1) + "-"
    delta_status: 200
    delta_dat: delta_dat
    delta_res: [
      {
        name: "test"
        mail: "sage"
        message: "abcde"
        other: "2007/06/14(水) 14:49:19 ID:aBcdEfgH"
      }
    ]
    last_dat: @machi_dat + delta_dat
  return

asyncTest "まちBBSの存在しないスレを取得しようとした時", 9, ->
  @test_machi_jbbs_none
    url: "http://__mockjax.machi.to/bbs/read.cgi/dummy/404/"
    dat_url: "http://__mockjax.machi.to/bbs/offlaw.cgi/dummy/404/"
    dat: "<ERROR>スレッドを発見できません</ERROR>"
  return

asyncTest "したらばのスレを取得出来る", 15, ->
  @test_200
    url: @jbbs_url
    dat_url: @jbbs_dat_url
    dat: @jbbs_dat
    thread_expected: @jbbs_expected
  return

asyncTest "したらばのスレの取得/更新テスト", 51, ->
  delta_dat = """
    6<>名無しさん<>sage<>2010/12/05(土) 22:57:40<>test<><>.aBCefGh

  """
  @test_update
    url: @jbbs_url
    dat_url: @jbbs_dat_url
    dat: @jbbs_dat
    thread_expected: @jbbs_expected
    delta_dat_url: @jbbs_dat_url + (@jbbs_expected.res.length + 1) + "-"
    delta_status: 200
    delta_dat: delta_dat
    delta_res: [
      {
        name: "名無しさん"
        mail: "sage"
        message: 'test'
        other: "2010/12/05(土) 22:57:40 ID:.aBCefGh"
      }
    ]
    last_dat: @jbbs_dat + delta_dat
  return

asyncTest "したらばの存在しないスレを取得しようとした時", 9, ->
  @test_machi_jbbs_none
    url: "http://jbbs.livedoor.jp/bbs/read.cgi/__mockjax/42710/404/"
    dat_url: "http://jbbs.livedoor.jp/bbs/rawmode.cgi/__mockjax/42710/404/"
    dat: ""
  return

asyncTest "したらばのスレを取得出来る(削除系確認)", 15, ->
  @test_200
    url: @jbbs_deleted_url
    dat_url: @jbbs_deleted_dat_url
    dat: @jbbs_deleted_dat
    thread_expected: @jbbs_deleted_expected
  return

asyncTest "BBSPINKのスレをパース出来る", 15, ->
  @test_200
    url: @pink_url
    dat_url: @pink_dat_url
    dat: @pink_dat
    thread_expected: @pink_expected
  return

module "Thread.parse"

test "[2ch]全ての行が破損データだった場合、nullを返す", 1, ->
  #2chで一部のスレを開いた時、302 -> 200で404.htmlが返される挙動になる事への対策
  html = """
  <html>
    <head><title>test</title></head>
    <body>
      Error
    </body>
  </html>
  """
  strictEqual(app.Thread.parse("http://hibari.2ch.net/test/read.cgi/pc/123/", html), null)
  return
