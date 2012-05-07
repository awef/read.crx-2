app.boot "/view/bookmark.html", ->
  $view = $(document.documentElement)

  $table = $("<table>")
  $table.thread_list("create", {
    th: ["title", "res", "unread", "heat", "created_date"]
    bookmark_add_rm: true
    searchbox: $view.find(".searchbox")
  })
  $table.appendTo(".content")
  $table.find("th.res, th.unread, th.heat").attr("data-table_sort_type", "num")
  $table.find("th.unread").addClass("table_sort_desc")
  $table.table_sort()

  app.view_module.view($view)
  app.view_module.sort_item_selector($view)
  app.view_module.tool_menu($view)

  #リロード時処理
  $view.on "request_reload", ->
    return if $view.hasClass("loading")
    $reload_button = $view.find(".button_reload")
    return if $reload_button.hasClass("disabled")

    $view.addClass("loading")
    $loading_overlay = $view.find(".loading_overlay")

    $reload_button.addClass("disabled")

    board_list = []
    for bookmark in app.bookmark.get_all() when bookmark.type is "thread"
      board_url = app.url.thread_to_board(bookmark.url)
      unless board_url in board_list
        board_list.push(board_url)

    for url in board_list
      text = url.replace(/// ^http:// ///, "").replace(/// /$ ///, "")
      $("<div>", {text, "data-url": url}).appendTo($loading_overlay)

    count =
      all: board_list.length
      loading: 0
      success: 0
      error: 0

    fn = (res) ->
      if res?
        count.loading--
        status = if res.status is "success" then "success" else "error"
        $loading_overlay
          .find("div[data-url=\"#{@prev}\"]")
            .toggleClass("loading #{status}")
        count[status]++

      if count.all is count.success + count.error
        #更新完了
        #ソート後にブックマークが更新されてしまう場合に備えて、少し待つ
        setTimeout(->
          $loading_overlay.empty()
          $view.find("table").table_sort("update", {
            sort_index: 2
            sort_type: "num"
            sort_order: "desc"
          })
          $view.removeClass("loading")
          setTimeout(->
            $reload_button.removeClass("disabled")
          , 1000 * 10)
          return
        , 500)
      # 合計最大同時接続数: 2
      # 同一サーバーへの最大接続数: 1
      else if count.loading < 2
        loading_server = (
          $loading_overlay
            .children(".loading")
              .map(-> $(@).attr("data-url").split("/")[2])
        )
        for current, key in board_list
          continue if current.split("/")[2] in loading_server
          board_list.splice(key, 1)
          $loading_overlay
            .find("div[data-url=\"#{current}\"]")
              .addClass("loading")
          count.loading++
          app.board.get(current, fn.bind(prev: current))
          fn()
          break
      return

    fn()
    return

  $table.thread_list "add_item",
    for a in app.bookmark.get_all() when a.type is "thread"
      title: a.title
      url: a.url
      res_count: a.res_count or 0
      read_state: a.read_state or {url: a.url, read: 0, received: 0, last: 0}
      created_at: /\/(\d+)\/$/.exec(a.url)[1] * 1000
      expired: a.expired

  app.message.send("request_update_read_state", {})
  $table.table_sort("update")

  $view.trigger("view_loaded")
  return
