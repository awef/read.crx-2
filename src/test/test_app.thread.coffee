module("app.thread._get_xhr_info")

test "スレのURLから、データのパスと文字コードを返す", 5, ->
  deepEqual(
    app.thread._get_xhr_info("http://qb5.2ch.net/test/read.cgi/operate/1234567890/"), {
      path: "http://qb5.2ch.net/operate/dat/1234567890.dat"
      charset: "Shift_JIS"
    }, "2ch"
  )

  deepEqual(
    app.thread._get_xhr_info("http://www.machi.to/bbs/read.cgi/tawara/511234524356/"), {
      path: "http://www.machi.to/bbs/offlaw.cgi/tawara/511234524356/"
      charset: "Shift_JIS"
    }, "まちBBS"
  )

  deepEqual(
    app.thread._get_xhr_info("http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273732874/"), {
      path: "http://jbbs.livedoor.jp/bbs/rawmode.cgi/computer/42710/1273732874/"
      charset: "EUC-JP"
    }, "したらば"
  )

  deepEqual(
    app.thread._get_xhr_info("http://pele.bbspink.com/test/read.cgi/erobbs/1297500876/"), {
      path: "http://pele.bbspink.com/erobbs/dat/1297500876.dat"
      charset: "Shift_JIS"
    }, "BBSPINK"
  )

  deepEqual(
    app.thread._get_xhr_info("http://ex14.vip2ch.com/test/read.cgi/part4vip/1289640497/"), {
      path: "http://ex14.vip2ch.com/part4vip/dat/1289640497.dat"
      charset: "Shift_JIS"
    }, "パー速"
  )

test "解釈できない文字列が渡された場合、nullを返す", 4, ->
  strictEqual(app.thread._get_xhr_info(""),
    null, "空URL")
  strictEqual(app.thread._get_xhr_info("awsedtfgyuhjikolp"),
    null, "ダミー文字列")
  strictEqual(app.thread._get_xhr_info("http://example.com/"), null,
    "いずれのタイプの掲示板にも当てはまらないURL")
  strictEqual(app.thread._get_xhr_info("http://example.com/test/hogehoge/fugafuga/"),
    null, "いずれのタイプの掲示板にも当てはまらないURL 2")

module("app.thread.parse")

test "2chのスレをパース出来る", 1, ->
  url = "http://qb5.2ch.net/test/read.cgi/operate/1234567890/"
  text = """
    ﾉtasukeruyo </b>忍法帖【Lv=10,xxxPT】<b> </b>◆0a./bc.def <b><><>2011/04/04(月) 10:19:46.92 ID:abcdEfGH0 BE:1234567890-2BP(1)<> テスト。 <br> http://qb5.2ch.net/test/read.cgi/operate/132452341234/1 <br> <hr><font color="blue">Monazilla/1.00 (V2C/2.5.1)</font> <>[test] テスト 123 [ﾃｽﾄ]
     </b>【東電 84.2 %】<b>  </b>◆0a./bc.def <b><>sage<>2011/04/04(月) 10:21:08.27 ID:abcdEfGH0<> てすとてすとテスト! <>
     </b>忍法帖【Lv=11,xxxPT】<b> <>sage<>2011/04/04(月) 10:24:46.33 ID:abc0DEFG1<> <a href="../test/read.cgi/operate/1234567890/1" target="_blank">&gt&gt1</a> <br> 乙 <br> てすとてすと試験てすと <>
    動け動けウゴウゴ２ちゃんねる<>sage<>2011/04/04(月) 10:25:17.27 ID:ABcdefgh0<> てすと、テスト <>
    動け動けウゴウゴ２ちゃんねる<><>2011/04/04(月) 10:25:51.88 ID:aBcdEfg+0<> てす <>
  """
  expected =
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
  deepEqual(app.thread.parse(url, text), expected)

test "まちBBSのスレをパース出来る", 1, ->
  #削除時の挙動確認用に>>3-4を削除
  #メール欄の確認用に>>5を改変
  url = "http://www.machi.to/bbs/read.cgi/tawara/511234524356/"
  text = """
    1<>まちこさん<><>2007/06/10(日) 09:20:35 ID:aBC.DeFG<>テストテストテスト。<br><br>sage推奨<>【test】色々testスレ（トリップテストとか）【テスト】　７題目
    2<>◆</b>1a2BC3DeFg<b><><>2007/06/11(月) 22:33:18 ID:Ab0cdeFG<>あ　い　う　え　tesu<>
    5<>◆</b>abcd.EfGHI<b><>sage<>2007/06/13(水) 14:49:19 ID:aBcdEfgH<>あ　い　う　え　tesu３<>
  """
  expected =
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
  deepEqual(app.thread.parse(url, text), expected)

test "したらばのスレをパース出来る", 1, ->
  #削除時の挙動確認用に>>3-4を削除
  url = "http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1290070091/"
  text = """
    1<><font color=#FF0000>awef★</font><><>2010/11/18(木) 17:48:11<>read.crxについての質問・要望・不具合報告等を気楽に書き込んで下さい<br><br>インストールはこちらから<br>ttps://chrome.google.com/extensions/detail/hhjpdicibjffnpggdiecaimdgdghainl<br>関連文章<br>ttp://wiki.livedoor.jp/awef/d/read.crx<br>UserVoice<br>ttp://readcrx.uservoice.com/<br>前スレ<br>ttp://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/<br><br>既出の要望・バグ等は全てUserVoiceで管理します<br>直接UserVoiceに投稿しちゃっても構いません<>read.crx総合 part2<>???
    2<>名無しさん<><>2010/12/03(金) 02:50:42<>試験用削除<><>ABCD0eFg
    5<>名無しさん<>sage<>2010/12/04(土) 22:57:40<><a href="/bbs/read.cgi/computer/42710/1290070091/2" target="_blank">&gt&gt2</a><br>少なくとも、今のブックマーク表示は、他の板とそれ程区別する必要は無いと思ってます<br><br><a href="/bbs/read.cgi/computer/42710/1290070091/4" target="_blank">&gt&gt4</a><br>サッとプロトコル見てみましたけど、多分無理っすね<br>こちら側も鯖立てないとムリっぽいし<><>.aBCefGh
  """
  expected =
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
  deepEqual(app.thread.parse(url, text), expected)

test "したらばのスレをパース出来る(削除系確認)", 1, ->
  url = "http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1310968239/"
  text = """
    1<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:50:39<>テスト<>削除レスとかの動作を確認するためのスレ<>???
    2<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:51:47<>テスト2<><>???
    3<>＜削除＞<>＜削除＞<>＜削除＞<>＜削除＞<><>
    4<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:53:07<><a href="/bbs/read.cgi/computer/42710/1310968239/3" target="_blank">&gt;&gt;3</a><br>削除<><>???
    6<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:54:08<><a href="/bbs/read.cgi/computer/42710/1310968239/5" target="_blank">&gt;&gt;5</a><br>透明削除<><>???
    7<><font color=#FF0000>awef★</font><><>2011/07/18(月) 14:55:04<><a href="/bbs/read.cgi/computer/42710/1310968239/8" target="_blank">&gt;&gt;8</a>, 9<br>透明削除<><>???
  """
  expected =
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
  deepEqual(app.thread.parse(url, text), expected)

test "BBSPINKのスレをパース出来る", 1, ->
  #簡略化のため、>>8を>>2に移動
  url = "http://pele.bbspink.com/test/read.cgi/erobbs/23455435345543/"
  text = """
    名無し編集部員<><>2008/03/22(土) 03:34:04 ID:aBcD0Ef1<> てすとてすとてすと <>レス削除練習用のスレ
    うふ～ん<>うふ～ん<>うふ～ん ID:DELETED<>うふ～ん<>うふ～ん<>
     </b>◆ABC/1/DEF. <b><><>2008/03/22(土) 03:53:57 ID:aB+C0Def<> てすと <>
  """
  expected =
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
  deepEqual(app.thread.parse(url, text), expected)
