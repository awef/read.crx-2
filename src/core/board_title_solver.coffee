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
  app.board_title_solver.ask = (url, callback) ->
    #場合によって同期か非同期か変わっても困るので、非同期で統一
    _callback = callback
    callback = (res) ->
      app.defer ->
        _callback(res)

    deferred_first_bbsmenu_update.done ->
      if dic_bbsmenu[url]?
        callback(dic_bbsmenu[url])
      else if bookmark = app.bookmark.get(url)
        if /// ^http://\w+\.2ch\.net/ ///.test(bookmark.url)
          callback(bookmark.title.replace("＠2ch掲示板", ""))
        else
          callback(bookmark.title)
      else
        callback(null)
)()
