module("board_title_solver")

# bbsmenu依存
asyncTest "BBSMenuから板名を取得する", 1, ->
  app.module null, ["board_title_solver"], (BoardTitleSolver) ->
    BoardTitleSolver
      .ask(url: "http://qb5.2ch.net/operate/", offline: true)
      .done (title) ->
        strictEqual(title, "2ch運用情報")
        start()
        return
    return
  return

# ブックマーク依存
asyncTest "ブックマークから板名を取得する", 1, ->
  app.module null, ["board_title_solver"], (BoardTitleSolver) ->
    BoardTitleSolver
      .ask(url: "http://jbbs.livedoor.jp/computer/42710/", offline: true)
      .done (title) ->
        strictEqual(title, "read.crx板")
        start()
        return
    return
  return

asyncTest "SETTING.TXTから板名を取得する", 4, ->
  app.module null, ["board_title_solver"], (BoardTitleSolver) ->
    $.mockjax
      url: "http://_____.2ch.net/__dummy/SETTING.TXT"
      status: 200
      responseText: """
        dummy@dummyGJJo4efoCO
        BBS_TITLE=dummy板＠2ch掲示板
        BBS_TITLE_PICTURE=http://img.2ch.net/img/dummy_a.gif
      """
      response: ->
        QUnit.step(2)
        return

    QUnit.step(1)

    BoardTitleSolver
      .ask(url: "http://_____.2ch.net/__dummy/", offline: false)
      .done (title) ->
        QUnit.step(3)
        strictEqual(title, "dummy板")
        $.mockjaxClear()
        start()
        return
    return
  return

asyncTest "したらばのAPIから板名を取得する", 4, ->
  app.module null, ["board_title_solver"], (BoardTitleSolver) ->
    $.mockjax
      url: "http://jbbs.livedoor.jp/bbs/api/setting.cgi/__dummy/01234/"
      status: 200
      responseText: """
        TOP=http://jbbs.livedoor.jp/__dummy/01234/
        DIR=__dummy
        BBS=01234
        CATEGORY=ダミーカテゴリ
        BBS_ADULT=0
        BBS_THREAD_STOP=1000
        BBS_NONAME_NAME=名無しさん
        BBS_DELETE_NAME=＜削除＞
        BBS_TITLE=ダミー板
        BBS_COMMENT=ダミーコメント
      """
      response: ->
        QUnit.step(2)
        return

    QUnit.step(1)

    BoardTitleSolver
      .ask(url: "http://jbbs.livedoor.jp/__dummy/01234/", offline: false)
      .done (title) ->
        QUnit.step(3)
        strictEqual(title, "ダミー板")
        $.mockjaxClear()
        start()
        return
    return
  return
