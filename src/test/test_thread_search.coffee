module "ThreadSearch",
  teardown: ->
    $.mockjaxClear()
    return

asyncTest "find.2ch.netの検索結果を取得できる", 6, ->
  $.mockjax
    url: "http://find.2ch.net/index.php?BBS=2ch&TYPE=TITLE&SORT=CREATED&STR=%A5%C6%A5%B9%A5%C8&OFFSET=0&_from=read.crx-2"
    status: 200
    responseText: """
dummy
<dt><a href="http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100">ダミースレッド&amp;テスト</a> (12) - <font size=-1><a href=http://__dummyserver.2ch.net/__dummyboard/>ダミー板</a>＠2ch</font></dt><dd><table border=0 cellpadding=0 cellspacing=0><tr><td class="r_sec_body">…テスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテストテストテストテスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテスト…<br /> <font size=-1><font color=#228822>最新:2012/04/19 12:16</font></font> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>板内</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+-board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>他の板</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+host%3A__dummyserver.2ch.net"><font color=gray>同じサーバ</font></a> <a href="index.php?TYPE=BODY&COUNT=10&STR=1234567890"><font color=gray>スレへのリンク</font></a> <font size=-1><a href="http://p2.2ch.net/p2/index.php?&url=http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100"><font color=gray>p2</font></a>で<a href="http://p2.2ch.net/p2/index.php?word=%83e%83X%83g&url=http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100"><font color=gray>抽出</font></a></font> <font size=-1><a href="index.php?TYPE=TITLE&STR=similar:__dummyboard/1234567890"><font color=gray>類似スレ</font></a></font></td></tr></table></dd>
<dt><a href="http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/1-100">ダミースレッド2 テスト</a> (120) - <font size=-1><a href=http://__dummyserver2.2ch.net/__dummyboard2/>ダミー板2</a>＠2ch</font></dt><dd><table border=0 cellpadding=0 cellspacing=0><tr><td class="r_sec_body">…テスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテストテストテストテスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテスト…<br /> <font size=-1><font color=#228822>最新:2012/04/19 12:16</font></font> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>板内</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+-board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>他の板</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+host%3A__dummyserver2.2ch.net"><font color=gray>同じサーバ</font></a> <a href="index.php?TYPE=BODY&COUNT=10&STR=1234567891"><font color=gray>スレへのリンク</font></a> <font size=-1><a href="http://p2.2ch.net/p2/index.php?&url=http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/1-100"><font color=gray>p2</font></a>で<a href="http://p2.2ch.net/p2/index.php?word=%83e%83X%83g&url=http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/1-100"><font color=gray>抽出</font></a></font> <font size=-1><a href="index.php?TYPE=TITLE&STR=similar:__dummyboard2/1234567891"><font color=gray>類似スレ</font></a></font></td></tr></table></dd>
<dt><a href="http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100">ダミースレッド テスト</a> (12) - <font size=-1><a href=http://__dummyserver.2ch.net/__dummyboard/>ダミー板</a>＠2ch</font></dt><dd><table border=0 cellpadding=0 cellspacing=0><tr><td class="r_sec_body">…テスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテストテストテストテスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテスト…<br /> <font size=-1><font color=#228822>最新:2012/04/19 12:16</font></font> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>板内</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+-board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>他の板</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+host%3A__dummyserver.2ch.net"><font color=gray>同じサーバ</font></a> <a href="index.php?TYPE=BODY&COUNT=10&STR=1234567890"><font color=gray>スレへのリンク</font></a> <font size=-1><a href="http://p2.2ch.net/p2/index.php?&url=http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100"><font color=gray>p2</font></a>で<a href="http://p2.2ch.net/p2/index.php?word=%83e%83X%83g&url=http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100"><font color=gray>抽出</font></a></font> <font size=-1><a href="index.php?TYPE=TITLE&STR=similar:__dummyboard/1234567890"><font color=gray>類似スレ</font></a></font></td></tr></table></dd>
ダミー
    """
    response: ->
      QUnit.step(2)
      return

  $.mockjax
    url: "http://find.2ch.net/index.php?BBS=2ch&TYPE=TITLE&SORT=CREATED&STR=%A5%C6%A5%B9%A5%C8&OFFSET=3&_from=read.crx-2"
    status: 200
    responseText: """
<dt><a href="http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100">ダミースレッド テスト</a> (12) - <font size=-1><a href=http://__dummyserver.2ch.net/__dummyboard/>ダミー板</a>＠2ch</font></dt><dd><table border=0 cellpadding=0 cellspacing=0><tr><td class="r_sec_body">…テスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテストテストテストテスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテスト…<br /> <font size=-1><font color=#228822>最新:2012/04/19 12:16</font></font> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>板内</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+-board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>他の板</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+host%3A__dummyserver.2ch.net"><font color=gray>同じサーバ</font></a> <a href="index.php?TYPE=BODY&COUNT=10&STR=1234567890"><font color=gray>スレへのリンク</font></a> <font size=-1><a href="http://p2.2ch.net/p2/index.php?&url=http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100"><font color=gray>p2</font></a>で<a href="http://p2.2ch.net/p2/index.php?word=%83e%83X%83g&url=http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/1-100"><font color=gray>抽出</font></a></font> <font size=-1><a href="index.php?TYPE=TITLE&STR=similar:__dummyboard/1234567890"><font color=gray>類似スレ</font></a></font></td></tr></table></dd>
<dt><a href="http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/1-100">ダミースレッド2 テスト</a> (120) - <font size=-1><a href=http://__dummyserver2.2ch.net/__dummyboard2/>ダミー板2</a>＠2ch</font></dt><dd><table border=0 cellpadding=0 cellspacing=0><tr><td class="r_sec_body">…テスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテストテストテストテスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテスト…<br /> <font size=-1><font color=#228822>最新:2012/04/19 12:16</font></font> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>板内</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+-board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>他の板</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+host%3A__dummyserver2.2ch.net"><font color=gray>同じサーバ</font></a> <a href="index.php?TYPE=BODY&COUNT=10&STR=1234567891"><font color=gray>スレへのリンク</font></a> <font size=-1><a href="http://p2.2ch.net/p2/index.php?&url=http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/1-100"><font color=gray>p2</font></a>で<a href="http://p2.2ch.net/p2/index.php?word=%83e%83X%83g&url=http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/1-100"><font color=gray>抽出</font></a></font> <font size=-1><a href="index.php?TYPE=TITLE&STR=similar:__dummyboard2/1234567891"><font color=gray>類似スレ</font></a></font></td></tr></table></dd>
<dt><a href="http://__dummyserver3.2ch.net/test/read.cgi/__dummyboard3/1234567890/1-100">ダミースレッド3 テスト</a> (123) - <font size=-1><a href=http://__dummyserver3.2ch.net/__dummyboard3/>ダミー板3</a>＠2ch</font></dt><dd><table border=0 cellpadding=0 cellspacing=0><tr><td class="r_sec_body">…テスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテストテストテストテスト テストテストテストテストテストテストテスト テストテストテストテストテストテストテスト…<br /> <font size=-1><font color=#228822>最新:2012/04/19 12:16</font></font> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>板内</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+-board%3A%A5%CF%A1%BC%A5%C9%A1%A6%B6%C8%B3%A6"><font color=gray>他の板</font></a> <a href="?TYPE=TITLE&COUNT=10&STR=%A5%C6%A5%B9%A5%C8+host%3A__dummyserver3.2ch.net"><font color=gray>同じサーバ</font></a> <a href="index.php?TYPE=BODY&COUNT=10&STR=1234567890"><font color=gray>スレへのリンク</font></a> <font size=-1><a href="http://p2.2ch.net/p2/index.php?&url=http://__dummyserver3.2ch.net/test/read.cgi/__dummyboard3/1234567890/1-100"><font color=gray>p2</font></a>で<a href="http://p2.2ch.net/p2/index.php?word=%83e%83X%83g&url=http://__dummyserver3.2ch.net/test/read.cgi/__dummyboard3/1234567890/1-100"><font color=gray>抽出</font></a></font> <font size=-1><a href="index.php?TYPE=TITLE&STR=similar:__dummyboard3/1234567890"><font color=gray>類似スレ</font></a></font></td></tr></table></dd>
    """
    response: ->
      QUnit.step(4)
      return

  app.module null, ["thread_search"], (ThreadSearch) ->
    search = new ThreadSearch("テスト")
    search.read().pipe (result) ->
      QUnit.step(3)
      deepEqual(result, [
        {
          url: "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
          title: "ダミースレッド&テスト"
          res_count: 12
          created_at: 1234567890000
          board_url: "http://__dummyserver.2ch.net/__dummyboard/"
          board_title: "ダミー板"
        }
        {
          url: "http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/"
          title: "ダミースレッド2 テスト"
          res_count: 120
          created_at: 1234567891000
          board_url: "http://__dummyserver2.2ch.net/__dummyboard2/"
          board_title: "ダミー板2"
        }
        {
          url: "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
          title: "ダミースレッド テスト"
          res_count: 12
          created_at: 1234567890000
          board_url: "http://__dummyserver.2ch.net/__dummyboard/"
          board_title: "ダミー板"
        }
      ])
      search.read()
    .done (result) ->
      deepEqual(result, [
        {
          url: "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
          title: "ダミースレッド テスト"
          res_count: 12
          created_at: 1234567890000
          board_url: "http://__dummyserver.2ch.net/__dummyboard/"
          board_title: "ダミー板"
        }
        {
          url: "http://__dummyserver2.2ch.net/test/read.cgi/__dummyboard2/1234567891/"
          title: "ダミースレッド2 テスト"
          res_count: 120
          created_at: 1234567891000
          board_url: "http://__dummyserver2.2ch.net/__dummyboard2/"
          board_title: "ダミー板2"
        }
        {
          url: "http://__dummyserver3.2ch.net/test/read.cgi/__dummyboard3/1234567890/"
          title: "ダミースレッド3 テスト"
          res_count: 123
          created_at: 1234567890000
          board_url: "http://__dummyserver3.2ch.net/__dummyboard3/"
          board_title: "ダミー板3"
        }
      ])
      start()
      return
    QUnit.step(1)
    return
  return

asyncTest "通信に失敗した場合はrejectする", 1, ->
  $.mockjax
    url: "http://find.2ch.net/index.php?BBS=2ch&TYPE=TITLE&SORT=CREATED&STR=%A5%C6%A5%B9%A5%C8&OFFSET=0&_from=read.crx-2"
    status: 501

  app.module null, ["thread_search"], (ThreadSearch) ->
    search = new ThreadSearch("テスト")
    search.read().fail (res) ->
      deepEqual(res, message: "通信エラー")
      start()
      return
    return
  return

asyncTest "結果が一件も無かった場合もresolveする", 1, ->
  $.mockjax
    url: "http://find.2ch.net/index.php?BBS=2ch&TYPE=TITLE&SORT=CREATED&STR=%A5%C6%A5%B9%A5%C8&OFFSET=0&_from=read.crx-2"
    status: 200
    responseText: "dummy"

  app.module null, ["thread_search"], (ThreadSearch) ->
    search = new ThreadSearch("テスト")
    search.read().done (res) ->
      deepEqual(res, [])
      start()
      return
    return
  return
