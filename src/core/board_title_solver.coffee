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

  # #app.board\_title\_solver.ask
  # 板のURLから板のタイトルを取得する  
  # callbackにはタイトル(string)かnullが渡される
  # TODO: $.Deferredを用いてリファクタリング
  app.board_title_solver.ask = (url, callback) ->
    #場合によって同期か非同期か変わっても困るので、非同期で統一
    _callback = callback
    callback = (res) ->
      app.defer ->
        _callback(res)

    deferred_first_bbsmenu_update.done ->
      #bbsmenu内を検索
      if dic_bbsmenu[url]?
        callback(dic_bbsmenu[url])

      #ブックマーク内を検索
      else if bookmark = app.bookmark.get(url)
        if /// ^http://\w+\.2ch\.net/ ///.test(bookmark.url)
          callback(bookmark.title.replace("＠2ch掲示板", ""))
        else
          callback(bookmark.title)

      #したらばのAPIから取得を試みる
      else if app.url.guess_type(url).bbs_type is "jbbs"
        xhr = new XMLHttpRequest()
        tmp = ///^http://(\w+\.(\w+\.\w+))/(\w+)/(?:(\d+)/)?$///.exec(url)
        xhr_path = "http://jbbs.livedoor.jp/bbs/api/setting.cgi/#{tmp[3]}/#{tmp[4]}/"
        xhr_timer = setTimeout((-> xhr.abort()), 1000 * 30)
        xhr.onreadystatechange = ->
          if xhr.readyState is 4
            clearTimeout(xhr_timer)
            if (xhr.status is 200) and
                (res = /^BBS_TITLE=(.+)$/m.exec(xhr.responseText))
              callback(res[1])
            else
              callback(null)
        xhr.overrideMimeType("text/plain; charset=EUC-JP")
        xhr.open("GET", xhr_path)
        xhr.send(null)

      #見つからなかったらnullを返す
      else
        callback(null)
)()
