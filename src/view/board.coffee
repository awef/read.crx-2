app.boot "/view/board.html", ->
  url = app.url.parse_query(location.href).q
  (alert("不正な引数です"); return) unless url?
  url = app.url.fix(url)
  opened_at = Date.now()

  $view = $(document.documentElement)
  $view
    .attr("data-url", url)
    .addClass("loading")

  $view.find("table").table_sort()

  app.view_module.view($view)
  app.view_module.searchbox_thread_title($view, 1)
  app.view_module.bookmark_button($view)
  app.view_module.link_button($view)
  app.view_module.board_contextmenu($view)
  app.view_module.sort_item_selector($view)

  app.board_title_solver.ask({url})
    .always (title) ->
      if title
        document.title = title
      app.history.add(url, title or url, opened_at)

  $view.bind "request_reload", ->
    return if $view.hasClass("loading")
    location.reload(true)
    return

  #ブックマーク更新処理
  app.message.add_listener "bookmark_updated", (message) ->
    if app.url.thread_to_board(message.bookmark.url) is url
      if message.type is "added" or message.type is "removed"
        $view
          .find("tr[data-href=\"#{message.bookmark.url}\"]")
            .find("td:nth-child(1)")
              .text(if message.type is "added" then "★" else "")

  #read_state更新時処理
  app.message.add_listener "read_state_updated", (message) ->
    if message.board_url is url
      tr = $view.find("tr[data-href=\"#{message.read_state.url}\"]")[0]
      if tr
        unread = message.read_state.received - message.read_state.read
        tr.children[3].textContent = Math.max(unread, 0) or ""

  app.view_board._draw($view)
    .done ->
      $button = $view.find(".button_reload")
      $button.addClass("disabled")
      setTimeout ->
        $button.removeClass("disabled")
      , 1000 * 5
      app.message.send("request_update_read_state", {board_url: url})

app.view_board = {}

app.view_board._draw = ($view) ->
  url = $view.attr("data-url")

  deferred_get_read_state = app.read_state.get_by_board(url)

  deferred_board_get = $.Deferred (deferred) ->
    app.board.get url, (res) ->
      $message_bar = $view.find(".message_bar")
      if res.status is "error"
        $message_bar.addClass("error").html(res.message)
      else
        $message_bar.removeClass("error").empty()

      if res.data?
        deferred.resolve(res.data)
      else
        deferred.reject()

  $.when(deferred_get_read_state, deferred_board_get)
    .done (array_of_read_state, board) ->
      read_state_index = {}
      for read_state, key in array_of_read_state
        read_state_index[read_state.url] = key

      now = Date.now()

      tbody = $view.find("tbody")[0]
      for thread in board
        tr = document.createElement("tr")
        tr.className = "open_in_rcrx"
        tr.setAttribute("data-href", thread.url)
        if read_state_index[thread.url]?
          read_state = array_of_read_state[read_state_index[thread.url]]
        else
          read_state = null

        #マーク
        td = document.createElement("td")
        if app.bookmark.get(thread.url)
          td.textContent = "★"
        tr.appendChild(td)

        #タイトル
        td = document.createElement("td")
        td.textContent = thread.title
        tr.appendChild(td)

        #レス数
        td = document.createElement("td")
        td.textContent = thread.res_count
        tr.appendChild(td)

        #未読数
        td = document.createElement("td")
        if read_state and thread.res_count > read_state.read
          td.textContent = thread.res_count - read_state.read
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

      $view.find("table").trigger("table_sort_update")

    .always ->
      $view.removeClass("loading")
      $view.trigger("view_loaded")
