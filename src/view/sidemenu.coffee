app.boot "/view/sidemenu.html", ->
  $view = $(document.documentElement)

  app.view_module.reload($view)
  app.view_module.open_in_rcrx($view)

  #スレタイ検索ボックス
  $view
    .find(".search")
      .bind "submit", ->
        app.defer =>
          this.STR.value = ""
        return

  board_to_li = (board) ->
    li = document.createElement("li")
    a = document.createElement("a")
    a.className = "open_in_rcrx"
    a.textContent = board.title
    a.href = app.safe_href(board.url)
    li.appendChild(a)
    li

  bookmark_to_li = board_to_li

  #ブックマークがない場合はブックマーク表示自体を隠し、有る場合は表示する
  sh_bookmark = ->
    $tmp = $view.find(".view_sidemenu_bookmark")
    if $tmp.children().length is 0
      $tmp.hide()
    else
      $tmp.show()

  load = ->
    app.bbsmenu.get (res) ->
      if res.message?
        app.notice.push(res.message)

      if res.data?
        frag = document.createDocumentFragment()
        for category in res.data
          h3 = document.createElement("h3")
          h3.textContent = category.title
          frag.appendChild(h3)

          ul = document.createElement("ul")
          for board in category.board
            ul.appendChild(board_to_li(board))
          frag.appendChild(ul)

      bookmark_frag = document.createDocumentFragment()
      for bookmark in app.bookmark.get_all()
        if bookmark.type is "board"
          bookmark_frag.appendChild(bookmark_to_li(bookmark))

      $view
        .find(".view_sidemenu_bookmark")
          .empty()
          .append(bookmark_frag)
        .end()
        .find("body")
          .append(frag)
          .accordion()
      sh_bookmark()

  $view.bind "request_reload", ->
    $view.find(".view_sidemenu_bookmark").empty()
    $view.find("h3:not(:first-of-type), ul:not(:first-of-type)").remove()
    load()
    return

  #ブックマーク更新時処理
  #TODO アンロード時にremove_listenerするよう改良
  app.message.add_listener "bookmark_updated", (message) ->
    if message.type is "added" and message.bookmark.type is "board"
      $tmp =  $view.find(".view_sidemenu_bookmark")
      if $tmp.find("a[href=\"#{message.bookmark.url}\"]").length is 0
        $tmp.append(bookmark_to_li(message.bookmark))
      sh_bookmark()
    else if message.type is "removed"
      $view
        .find(".view_sidemenu_bookmark")
          .find("a[href=\"#{message.bookmark.url}\"]")
            .parent()
              .remove()
      sh_bookmark()

  load()

