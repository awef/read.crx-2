`/** @namespace */`
app.board_title_solver = {}

(->
  dic_bbsmenu = {}

  update_dic_bbsmenu = ->
    app.bbsmenu.get (result) ->
      console.log result
      if "data" of result
        for category in result.data
          for board in category.board
            dic_bbsmenu[board.url] = board.title
        console.log(dic_bbsmenu)

  $(-> update_dic_bbsmenu())

  `/**
   * @param url {fixed_url}
   * @param callback {Function}
   */`
  app.board_title_solver.ask = (url, callback) ->
    #callback(title) or callback(null)
    if url of dic_bbsmenu
      callback(dic_bbsmenu[url])
    else
      callback(null)
)()
