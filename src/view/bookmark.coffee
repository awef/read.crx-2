app.view_bookmark = {}

app.view_bookmark._bookmark_to_tr = (bookmark) ->
  tr = document.createElement("tr")
  tr.className = "open_in_rcrx"
  tr.setAttribute("data-href", bookmark.url)
  tr.setAttribute("data-title", bookmark.title)

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

app.boot "/view/bookmark.html", ->
  $view = $(document.documentElement)

  $view.find("table").table_sort()

  app.view_module.view($view)
  app.view_module.searchbox_thread_title($view, 0)
  app.view_module.board_contextmenu($view)
  app.view_module.sort_item_selector($view)
  app.view_module.board_title($view)
  app.view_module.link_button($view)

  #リロード時処理
  $view.bind "request_reload", ->
    return if $view.hasClass("loading")

    $view
      .addClass("loading")
      .find(".searchbox_thread_title")
        .val("")

    $loading_overlay = $view.find(".loading_overlay")

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
        location.reload(true)
    fn()
    return

  #ブックマーク更新時処理
  app.message.add_listener "bookmark_updated", (message) ->
    return if message.bookmark.type isnt "thread"

    switch message.type
      when "added"
        $view
          .find("tbody")
            .append(app.view_bookmark._bookmark_to_tr(message.bookmark))
          .end()
          .find("table")
            .table_sort("update")
      when "removed"
        $view.find("tr[data-href=\"#{message.bookmark.url}\"]").remove()
      when "res_count", "expired", "title"
        $view
          .find("tr[data-href=\"#{message.bookmark.url}\"]")
            .replaceWith(app.view_bookmark._bookmark_to_tr(message.bookmark))

  #read_state更新時処理
  app.message.add_listener "read_state_updated", (message) ->
    if bookmark = app.bookmark.get(message.read_state.url)
      $tr = $view.find("tr[data-href=\"#{message.read_state.url}\"]")
      if $tr.length is 1
        bookmark.read_state = message.read_state
        $tr.replaceWith(app.view_bookmark._bookmark_to_tr(bookmark))

  #描画処理
  do ->
    frag = document.createDocumentFragment()

    for bookmark in app.bookmark.get_all()
      if bookmark.type is "thread"
        frag.appendChild(app.view_bookmark._bookmark_to_tr(bookmark))

    $view.find("tbody").append(frag)
    $view.find("table").table_sort("update")
    $view.trigger("view_loaded")

  app.message.send("request_update_read_state", {})
