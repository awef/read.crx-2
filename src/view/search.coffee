app.boot "/view/search.html", ["thread_search"], (ThreadSearch) ->
  query = app.url.parse_query(location.href).query

  unless query?
    alert("不正な引数です")
    return

  opened_at = Date.now()

  $view = $(document.documentElement)
  $view.attr("data-url", "search:#{query}")

  $message_bar = $view.find(".message_bar")

  app.view_module.view($view)
  app.view_module.searchbox_thread_title($view, 1)
  app.view_module.board_contextmenu($view)
  app.view_module.board_title($view)

  document.title = "検索:#{query}"
  app.history.add($view.attr("data-url"), document.title, opened_at)

  #ブックマーク更新処理
  app.message.add_listener "bookmark_updated", (message) ->
    if message.type is "added" or message.type is "removed"
      $view
        .find("tr[data-href=\"#{message.bookmark.url}\"] > td:nth-child(1)")
          .text(if message.type is "added" then "★" else "")
    return

  thread_search = new ThreadSearch(query)
  tbody = $view.find("tbody")[0]

  load = ->
    return if $view.hasClass("loading")
    $view.addClass("loading")
    $view.find(".more").text("検索中")
    thread_search.read()
      .done (result) ->
        $message_bar.removeClass("error").empty()

        now = Date.now()

        for thread in result
          tr = document.createElement("tr")
          tr.className = "open_in_rcrx"
          tr.setAttribute("data-href", thread.url)
          tr.setAttribute("data-title", thread.title)

          #マーク
          td = document.createElement("td")
          if app.bookmark.get(thread.url)
            td.textContent = "★"
          tr.appendChild(td)

          #タイトル
          td = document.createElement("td")
          td.textContent = thread.title
          tr.appendChild(td)

          #板名
          td = document.createElement("td")
          td.textContent = thread.board_title
          tr.appendChild(td)

          #レス数
          td = document.createElement("td")
          td.textContent = thread.res_count
          tr.appendChild(td)

          #勢い
          td = document.createElement("td")
          td.textContent = app.util.calc_heat(now, thread.created_at, thread.res_count)
          tr.appendChild(td)

          #作成日時
          td = document.createElement("td")
          td.textContent = app.util.date_to_string(new Date(thread.created_at))
          tr.appendChild(td)

          tbody.appendChild(tr)

        $view.find(".more").text("更に読み込む")

        if result.length isnt 10
          $view.find(".more").hide()

        $view.removeClass("loading")
        return
      .fail (res) ->
        $message_bar.addClass("error").text(res.message)
        $view.find(".more").hide()
        $view.removeClass("loading")
        return
    return

  $view.find(".more").on("click", load)
  load()
  return
