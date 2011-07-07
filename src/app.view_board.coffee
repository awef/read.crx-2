app.view_board = {}

app.view_board.open = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()

  $view = $("#template > .view_board").clone()
  $view
    .attr("data-url", url)
    .attr("data-title", url)
    .addClass("loading")

  app.view_module.searchbox_thread_title($view, 1)
  app.view_module.bookmark_button($view)
  app.view_module.link_button($view)
  app.view_module.reload_button($view)
  app.view_module.board_contextmenu($view)

  app.board_title_solver.ask url, (title) ->
    if title
      $view.attr("data-title", title)
      $view.trigger("title_updated")
    app.history.add(url, title or url, opened_at)

  #リロードボタンを一時的に無効化する
  suspend_reload_button = ->
    $button = $view.find(".button_reload")
    $button.addClass("disabled")
    setTimeout ->
      $button.removeClass("disabled")
    , 1000 * 5

  $view.bind "request_reload", ->
    if $view.hasClass("loading")
      return

    $view.addClass("loading")
    $view.find("tbody").empty()
    app.view_board._draw($view)
      .done ->
        suspend_reload_button()

  #ブックマーク更新処理
  on_bookmark_updated = (message) ->
    if app.url.thread_to_board(message.bookmark.url) is url
      if message.type is "added" or message.type is "removed"
        $view
          .find("tr[data-href=\"#{message.bookmark.url}\"]")
            .find("td:nth-child(1)")
              .text(if message.type is "added" then "★" else "")

  app.message.add_listener("bookmark_updated", on_bookmark_updated)

  $view.bind "view_unload", ->
    app.message.remove_listener("bookmark_updated", on_bookmark_updated)

  #read_state更新時処理
  on_read_state_updated = (message) ->
    if message.board_url is url
      tr = $view.find("tr[data-href=\"#{message.read_state.url}\"]")[0]
      if tr
        text = "" + ((message.read_state.received - message.read_state.read) or "")
        tr.children[3].textContent = text

  app.message.add_listener("read_state_updated", on_read_state_updated)

  $view.bind "view_unload", ->
    app.message.remove_listener("read_state_updated", on_read_state_updated)

  app.view_board._draw($view)
    .done ->
      suspend_reload_button()

  $view.find("table").table_sort()

  $view

app.view_board._draw = ($view) ->
  url = $view.attr("data-url")

  deferred_get_read_state = app.read_state.get_by_board(url)

  deferred_board_get = $.Deferred (deferred) ->
    app.board.get url, (res) ->
      $message_bar = $view.find(".message_bar")
      if res.status is "error"
        $message_bar.addClass("error").html(res.message)

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

      $view.find("table").trigger("table_sort_update")

    .always ->
      $view.removeClass("loading")
