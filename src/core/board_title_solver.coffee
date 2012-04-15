app.module "board_title_solver", ["jquery", "bbsmenu"], ($, BBSMenu, callback) ->
  class BoardTitleSolver
    constructor: ->
      @_bbsmenu_ready = $.Deferred()
      @_dic_bbsmenu = {}

      # TODO 何で$()なのか調査
      $(=> @update_dic_bbsmenu())
      return

    update_dic_bbsmenu: ->
      BBSMenu.get (result) =>
        if result.data?
          for category in result.data
            for board in category.board
              @_dic_bbsmenu[board.url] = board.title
        @_bbsmenu_ready.resolve()
        return
      return

    # 板のURLから板のタイトルを取得する
    # prop.url, prop.offline
    ask: (prop) ->
      url = app.url.fix(prop.url)
      @_bbsmenu_ready
        #bbsmenu内を検索
        .pipe => $.Deferred (d) =>
          if @_dic_bbsmenu[url]?
            d.resolve(@_dic_bbsmenu[url])
          else
            d.reject()
          return
        #ブックマーク内を検索
        .pipe null, -> $.Deferred (d) ->
          if bookmark = app.bookmark.get(url)
            if app.url.tsld(bookmark.url) is "2ch.net"
              d.resolve(bookmark.title.replace("＠2ch掲示板", ""))
            else
              d.resolve(bookmark.title)
          else
            d.reject()
          return
        #SETTING.TXTからの取得を試みる
        .pipe null, ->
          return if prop.offline or app.url.guess_type(url).bbs_type isnt "2ch"
          $.ajax url + "SETTING.TXT",
            dataType: "text"
            timeout: 1000 * 10
            beforeSend: (jqxhr) ->
              jqxhr.overrideMimeType("text/plain; charset=Shift_JIS")
              return
          .pipe (text) -> $.Deferred (d) ->
            if res = /^BBS_TITLE=(.+)$/m.exec(text)
              d.resolve(res[1].replace("＠2ch掲示板", ""))
            else
              d.reject()
            return
          #$.ajaxの吐く余分なデータの削除
          , -> $.Deferred().reject()
        #したらばのAPIから取得を試みる
        .pipe null, ->
          return if prop.offline or app.url.guess_type(url).bbs_type isnt "jbbs"
          tmp = url.split("/")
          ajax_path = "http://jbbs.livedoor.jp/bbs/api/setting.cgi/#{tmp[3]}/#{tmp[4]}/"
          $.ajax ajax_path,
            dataType: "text"
            timeout: 1000 * 10
            beforeSend: (jqxhr) ->
              jqxhr.overrideMimeType("text/plain; charset=EUC-JP")
              return
          .pipe (text) -> $.Deferred (d) ->
            if res = /^BBS_TITLE=(.+)$/m.exec(text)
              d.resolve(res[1])
            else
              d.reject()
            return
          #$.ajaxの吐く余分なデータの削除
          , -> $.Deferred().reject()
        .promise()

  callback(new BoardTitleSolver)
  return
