app.view.board = {}

app.view.board.open = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()

  $view = $("#template > .view_board").clone()
  $view
    .attr("data-url", url)
    .attr("data-title", url)

  app.view.module.searchbox_thread_title($view, 1)
  app.view.module.bookmark_button($view)
  app.view.module.link_button($view)
  app.view.module.reload_button($view)

  $("#tab_a").tab("add", element: $view[0], title: url)

  app.board_title_solver.ask url, (res) ->
    if res
      title = res
      $view
        .closest(".tab")
        .tab "update_title",
          tab_id: $view.attr("data-tab_id")
          title: title
      $view.attr("data-title", title)
    app.history.add(url, title or url, opened_at)

  $view.bind "request_reload", ->
    $loading_overlay = $view.find(".loading_overlay").show()
    $view.find("tbody").empty()
    $view
      .find(".table_sort_desc, .table_sort_asc")
        .removeClass("table_sort_desc table_sort_asc")
    app.view.board._draw($view)

  app.view.board._draw($view)
  $view.find("table").table_sort()

app.view.board._draw = ($view) ->
  url = $view.attr("data-url")

  deferred_get_read_state = app.read_state.get_by_board(url)

  deferred_board_get = $.Deferred (deferred) ->
    app.board.get url, (res) ->
      $message_bar = $view.find(".message_bar")
      if res.status is "error"
        text = "板の読み込みに失敗しました。"
        if "data" of res
          text += "キャッシュに残っていたデータを表示します。"
        $message_bar.addClass("error").text(text)

      if "data" of res
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
        if thread.url of read_state_index
          read_state = array_of_read_state[read_state_index[thread.url]]
        else
          read_state = null

        td = document.createElement("td")
        if app.bookmark.get(thread.url)
          td.textContent = "★"
        tr.appendChild(td)

        td = document.createElement("td")
        td.textContent = thread.title
        tr.appendChild(td)

        td = document.createElement("td")
        td.textContent = thread.res_count
        tr.appendChild(td)

        td = document.createElement("td")
        if read_state and thread.res_count > read_state.read
          td.textContent = thread.res_count - read_state.read
        tr.appendChild(td)

        td = document.createElement("td")
        td.textContent = app.util.calc_heat(now, thread.created_at, thread.res_count)
        tr.appendChild(td)

        td = document.createElement("td")
        td.textContent = app.util.date_to_string(new Date(thread.created_at))
        tr.appendChild(td)

        tbody.appendChild(tr)
      null
    .always ->
      $view.find(".loading_overlay").fadeOut(100)