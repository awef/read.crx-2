app.view.open_board = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()

  $view = $("#template > .view_board").clone()
  $view
    .attr("data-url", url)

    .find(".searchbox_thread_title")
      .bind "input", ->
        $view
          .find("table")
            .table_search("search", query: this.value, target_col: 1)
      .bind "keyup", (e) ->
        if e.which is 27 #Esc
          this.value = ""
          $view.find("table").table_search("clear")

  app.view.module.bookmark_button($view)
  app.view.module.link_button($view)

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

  app.view._open_board_draw($view)

app.view._open_board_draw = ($view) ->
  url = $view.attr("data-url")

  deferred_get_read_state = $.Deferred (deferred) ->
    app.read_state.get_by_board url, (res) ->
      if res.status is "success"
        deferred.resolve(res.data)
      else
        deferred.reject()

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
          td.innerText = "★"
        tr.appendChild(td)

        td = document.createElement("td")
        td.innerText = thread.title
        tr.appendChild(td)

        td = document.createElement("td")
        td.innerText = thread.res_count
        tr.appendChild(td)

        td = document.createElement("td")
        if read_state and thread.res_count > read_state.read
          td.innerText = thread.res_count - read_state.read
        tr.appendChild(td)

        td = document.createElement("td")
        td.innerText = app.util.calc_heat(now, thread.created_at, thread.res_count)
        tr.appendChild(td)

        td = document.createElement("td")
        td.innerText = app.util.date_to_string(new Date(thread.created_at))
        tr.appendChild(td)

        tbody.appendChild(tr)
      $view.find("table").table_sort()
    .always ->
      $view.find(".loading_overlay").fadeOut(100)
