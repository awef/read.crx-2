app.boot "/view/sidemenu.html", ->
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
      .bind "keydown", (e) ->
        if e.which is 27 #Esc
          @STR.value = ""
        return

      .bind "submit", ->
        app.defer =>
          @STR.value = ""
        return

  #ブックマーク関連
  (->
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
      if message.type is "added" and message.bookmark.type is "board"
        $tmp = $view.find("ul:first-of-type")
        if $tmp.find("a[href=\"#{message.bookmark.url}\"]").length is 0
          $tmp.append(bookmark_to_li(message.bookmark))
      else if message.type is "removed"
        $view
          .find("ul:first-of-type")
            .find("a[href=\"#{message.bookmark.url}\"]")
              .parent()
                .remove()
  )()

  #板覧関連
  (->
    load = ->
      $view.addClass("loading")
      app.bbsmenu.get (res) ->
        if res.message?
          app.message.send("notify", message: res.message)

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

    $view.bind "request_reload", ->
      $view.find("h3:not(:first-of-type), ul:not(:first-of-type)").remove()
      load()
      return

    load()
  )()
