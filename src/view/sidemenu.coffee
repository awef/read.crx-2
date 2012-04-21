app.boot "/view/sidemenu.html", ["bbsmenu"], (BBSMenu) ->
  $view = $(document.documentElement)

  board_to_li = (board) ->
    li = document.createElement("li")
    a = document.createElement("a")
    a.className = "open_in_rcrx"
    a.textContent = board.title
    a.href = app.safe_href(board.url)
    li.appendChild(a)
    li

  bookmark_to_li = (bookmark) ->
    li = board_to_li(bookmark)
    li.classList.add("bookmark")
    li

  app.view_module.view($view)

  #スレタイ検索ボックス
  $view
    .find(".search")
      .on "keydown", (e) ->
        if e.which is 27 #Esc
          @q.value = ""
        return

      .on "submit", (e) ->
        e.preventDefault()
        app.message.send("open", {url: "search:#{@q.value}", new_tab: true})
        @q.value = ""
        return

  #ブックマーク関連
  do ->
    #初回ブックマーク表示構築
    app.bookmark.promise_first_scan.done ->
      frag = document.createDocumentFragment()

      for bookmark in app.bookmark.get_all()
        if bookmark.type is "board"
          frag.appendChild(bookmark_to_li(bookmark))

      $view
        .find("ul:first-of-type")
          .append(frag)
        .end()
        .find("body")
          .accordion()

    #ブックマーク更新時処理
    app.message.add_listener "bookmark_updated", (message) ->
      return if message.bookmark.type isnt "board"

      switch message.type
        when "added"
          if $view.find("li.bookmark > a[href=\"#{message.bookmark.url}\"]").length is 0
            $view
              .find("ul:first-of-type")
                .append(bookmark_to_li(message.bookmark))
        when "removed"
          $view
            .find("li.bookmark > a[href=\"#{message.bookmark.url}\"]")
              .parent()
                .remove()
        when "title"
          $view
            .find("li.bookmark > a[href=\"#{message.bookmark.url}\"]")
              .text(message.bookmark.title)

  #板覧関連
  do ->
    load = ->
      $view.addClass("loading")
      BBSMenu.get (res) ->
        $view.find("h3:not(:first-of-type), ul:not(:first-of-type)").remove()

        if res.message?
          app.message.send("notify", {
            message: res.message
            background_color: "red"
          })

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

        $view
          .find("body")
            .append(frag)
            .accordion()
        $view.removeClass("loading")
        return
      return

    $view.on "request_reload", ->
      load()
      return

    load()
    return
  return
