describe "app.BoardTitleSolver", ->
  app.bookmark ?= get: -> return

  beforeEach ->
    spyOn(app.BBSMenu, "get").andCallFake (callback) ->
      callback(
        status: "success"
        data: [
          {
            title: "ダミーカテゴリ"
            board: [
              {
                url: "http://dummy.2ch.net/dummy/"
                title: "ダミー板"
              }
            ]
          }
        ]
      )
      return

    spyOn(app.bookmark, "get").andCallFake (url) ->
      if url is "http://aaaaa.2ch.net/bbbbb/"
        {
          url: "http://aaaaa.2ch.net/bbbbb/"
          title: "abcde"
          type: "board"
          bbs_type: "2ch"
          res_count: null
          read_state: null
          expired: false
        }
      else
        null
    return

  it "BBSMenuから板名を取得する", ->
    completed = false

    app.BoardTitleSolver.ask(url: "http://dummy.2ch.net/dummy/", offline: true)
      .done (title) ->
        expect(title).toBe("ダミー板")
        completed = true
        return

    waitsFor ->
      completed
    return

  it "ブックマークから板名を取得する", ->
    completed = false

    app.BoardTitleSolver.ask(url: "http://aaaaa.2ch.net/bbbbb/", offline: true)
      .done (title) ->
        expect(title).toBe("abcde")
        completed = true
        return

    waitsFor ->
      completed
    return

  it "SETTING.TXTから板名を取得する", ->
    completed = false

    $.mockjax
      url: "http://12345.2ch.net/23456/SETTING.TXT"
      status: 200
      responseText: """
        dummy@dummyGJJo4efoCO
        BBS_TITLE=34567＠2ch掲示板
        BBS_TITLE_PICTURE=http://img.2ch.net/img/dummy_a.gif
      """

    app.BoardTitleSolver.ask(url: "http://12345.2ch.net/23456/", offline: false)
      .done (title) ->
        expect(title).toBe("34567")
        completed = true
        return

    waitsFor ->
      completed

    runs ->
      $.mockjaxClear()
      return
    return

  it "したらばのAPIから板名を取得する", ->
    completed = false

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

    app.BoardTitleSolver
      .ask(url: "http://jbbs.livedoor.jp/__dummy/01234/", offline: false)
      .done (title) ->
        expect(title).toBe("ダミー板")
        completed = true
        return

    waitsFor ->
      completed

    runs ->
      $.mockjaxClear()
      return
    return
  return
