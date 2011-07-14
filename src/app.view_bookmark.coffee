app.view_bookmark = {}

app.view_bookmark.open = ->
  $view = $("#template > .view_bookmark").clone()

  $loading_overlay = $view.find(".loading_overlay")

  $view.find("table").table_sort()

  $view.find(".button_link").bind "click", ->
    path = "chrome-extension://eemcgdkfndhakfknompkggombfjjjeno/"
    path += "main.html##{app.config.get("bookmark_id")}"
    open(path)
    return

  app.view_module.reload_button($view)
  app.view_module.searchbox_thread_title($view, 0)
  app.view_module.board_contextmenu($view)

  $view.bind "request_reload", ->
    if $view.hasClass("loading")
      return

    $view.addClass("loading")

    board_list = []
    for bookmark in app.bookmark.get_all()
      if bookmark.type is "thread"
        board_url = app.url.thread_to_board(bookmark.url)
        unless board_url in board_list
          board_list.push(board_url)

    $prev = null
    fn = (result) ->
      if result
        if result.status is "success"
          $prev.toggleClass("loading success")
        else
          $prev.toggleClass("loading fail")

      if board_list.length > 0
        board_url = board_list[0]
        board_list.splice(0, 1)
        $prev = $("<div>", text: board_url, class: "loading")
        $prev.prependTo($loading_overlay)
        app.board.get(board_url, fn)
      else
        $view.find("tbody").empty()
        app.view_bookmark._draw($view)
        $loading_overlay.empty()
    fn()
    return

  #ブックマーク更新時処理
  on_updated = (message) ->
    if message.type is "added" and message.bookmark.type is "thread"
      $view
        .find("tbody")
          .append(app.view_bookmark._bookmark_to_tr(message.bookmark))
        .end()
        .find("table")
          .trigger("table_sort_update")

    else if message.type is "removed"
      $view.find("tr[data-href=\"#{message.bookmark.url}\"]").remove()

    else if message.type is "expired"
      $tr = $view.find("tr[data-href=\"#{message.bookmark.url}\"]")
      if $tr.length is 1
        $tr.replaceWith(app.view_bookmark._bookmark_to_tr(message.bookmark))

  app.message.add_listener("bookmark_updated", on_updated)

  $view.bind "view_unload", ->
    app.message.remove_listener("bookmark_updated", on_updated)
    return

  #read_state更新時処理
  on_read_state_updated = (message) ->
    if bookmark = app.bookmark.get(message.read_state.url)
      $tr = $view.find("tr[data-href=\"#{message.read_state.url}\"]")
      if $tr.length is 1
        bookmark.read_state = message.read_state
        $tr.replaceWith(app.view_bookmark._bookmark_to_tr(bookmark))

  app.message.add_listener("read_state_updated", on_read_state_updated)

  $view.bind "view_unload", ->
    app.message.remove_listener("read_state_updated", on_read_state_updated)
    return

  app.view_bookmark._draw($view)

  $view

app.view_bookmark._draw = ($view) ->
  frag = document.createDocumentFragment()

  for bookmark in app.bookmark.get_all()
    if bookmark.type is "thread"
      frag.appendChild(app.view_bookmark._bookmark_to_tr(bookmark))

  $view.find("tbody").append(frag)
  $view.find("table").trigger("table_sort_update")
  $view.removeClass("loading")
  $view.trigger("view_loaded")

app.view_bookmark._bookmark_to_tr = (bookmark) ->
  tr = document.createElement("tr")
  tr.className = "open_in_rcrx"
  tr.setAttribute("data-href", bookmark.url)

  if bookmark.expired is true
    tr.classList.add("expired")

  thread_created_at = +/// /(\d+)/$ ///.exec(bookmark.url)[1] * 1000

  #タイトル
  td = document.createElement("td")
  td.textContent = bookmark.title
  tr.appendChild(td)

  #レス数
  td = document.createElement("td")
  td.textContent = bookmark.res_count or 0
  tr.appendChild(td)

  #未読レス数
  td = document.createElement("td")
  if typeof bookmark.res_count is "number"
    unread = bookmark.res_count - (bookmark.read_state?.read or 0)
    unread = Math.max(unread, 0)
    td.textContent = unread or ""
  tr.appendChild(td)

  #勢い
  td = document.createElement("td")
  if typeof bookmark.res_count is "number"
    td.textContent = app.util.calc_heat(Date.now(), thread_created_at, bookmark.res_count)
  tr.appendChild(td)

  #作成日時
  td = document.createElement("td")
  td.textContent = app.util.date_to_string(new Date(thread_created_at))
  tr.appendChild(td)

  tr
