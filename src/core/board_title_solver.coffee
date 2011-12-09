app.board_title_solver = {}

do ->
  deferred_first_bbsmenu_update = $.Deferred()

  dic_bbsmenu = {}

  update_dic_bbsmenu = ->
    app.bbsmenu.get (result) ->
      if result.data?
        for category in result.data
          for board in category.board
            dic_bbsmenu[board.url] = board.title
      deferred_first_bbsmenu_update.resolve()

  $(-> update_dic_bbsmenu())

  # 板のURLから板のタイトルを取得する
  # prop.url, prop.offline
  app.board_title_solver.ask = (prop) ->
    url = prop.url
    deferred_first_bbsmenu_update
      #bbsmenu内を検索
      .pipe ->
        $.Deferred (deferred) ->
          if dic_bbsmenu[url]?
            deferred.resolve(dic_bbsmenu[url])
          else
            deferred.reject()
      #ブックマーク内を検索
      .pipe null, ->
        $.Deferred (deferred) ->
          if bookmark = app.bookmark.get(url)
            if app.url.tsld(bookmark.url) is "2ch.net"
              deferred.resolve(bookmark.title.replace("＠2ch掲示板", ""))
            else
              deferred.resolve(bookmark.title)
          else
            deferred.reject()
      #SETTING.TXTからの取得を試みる
      .pipe null, ->
        return if prop.offline or app.url.guess_type(url).bbs_type isnt "2ch"
        $.ajax url + "SETTING.TXT",
          dataType: "text"
          timeout: 1000 * 10
          beforeSend: (jqxhr) ->
            jqxhr.overrideMimeType("text/plain; charset=Shift_JIS")
        .pipe (text) ->
          $.Deferred (deferred) ->
            if res = /^BBS_TITLE=(.+)$/m.exec(text)
              deferred.resolve(res[1])
            else
              deferred.reject()
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
        .pipe (text) ->
          $.Deferred (deferred) ->
            if res = /^BBS_TITLE=(.+)$/m.exec(text)
              deferred.resolve(res[1])
            else
              deferred.reject()
        #$.ajaxの吐く余分なデータの削除
        , -> $.Deferred().reject()
      .promise()
