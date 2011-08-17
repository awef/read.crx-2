app.board_title_solver = {}

(->
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
      #したらばのAPIから取得を試みる
      .pipe null, ->
        $.Deferred (deferred) ->
          if (not prop.offline) and app.url.guess_type(url).bbs_type is "jbbs"
            xhr = new XMLHttpRequest()
            tmp = ///^http://(\w+\.(\w+\.\w+))/(\w+)/(?:(\d+)/)?$///.exec(url)
            xhr_path = "http://jbbs.livedoor.jp/bbs/api/setting.cgi/#{tmp[3]}/#{tmp[4]}/"
            xhr_timer = setTimeout((-> xhr.abort()), 1000 * 30)
            xhr.onreadystatechange = ->
              if xhr.readyState is 4
                clearTimeout(xhr_timer)
                if (xhr.status is 200) and
                    (res = /^BBS_TITLE=(.+)$/m.exec(xhr.responseText))
                  deferred.resolve(res[1])
                else
                  deferred.reject()
            xhr.overrideMimeType("text/plain; charset=EUC-JP")
            xhr.open("GET", xhr_path)
            xhr.send(null)
          else
            deferred.reject()
      .promise()
)()
