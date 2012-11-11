app.boot "/view/bookmark.html", ->
  $view = $(document.documentElement)

  $table = $("<table>")
  threadList = new UI.ThreadList($table[0], {
    th: ["title", "res", "unread", "heat", "createdDate"]
    bookmarkAddRm: true
    searchbox: $view.find(".searchbox")[0]
  })
  $view.data("threadList", threadList)
  $table.appendTo(".content")
  $table.find("th.res, th.unread, th.heat").attr("data-table_sort_type", "num")
  $table.find("th.unread").addClass("table_sort_desc")
  $table.table_sort()

  app.view_module.view($view)
  app.view_module.sort_item_selector($view)
  app.view_module.tool_menu($view)

  trUpdatedObserver = new WebKitMutationObserver (records) ->
    for record in records
      if record.target.webkitMatchesSelector("tr.updated")
        record.target.parentNode.appendChild(record.target)
    return

  #リロード時処理
  $view.on "request_reload", ->
    return if $view.hasClass("loading")
    $reload_button = $view.find(".button_reload")
    return if $reload_button.hasClass("disabled")

    $view.addClass("loading")
    $view.find(".searchbox").prop("disabled", true)
    $loading_overlay = $view.find(".loading_overlay")

    $reload_button.addClass("disabled")

    trUpdatedObserver.observe($view[0].querySelector("tbody"), {
      subtree: true
      attributes: true
      attributeFilter: ["class"]
    })

    board_list = []
    for bookmark in app.bookmark.get_all() when bookmark.type is "thread"
      board_url = app.url.thread_to_board(bookmark.url)
      unless board_url in board_list
        board_list.push(board_url)

    count =
      all: board_list.length
      loading: 0
      success: 0
      error: 0

    loadingServer = {}

    fn = (res) ->
      if res?
        delete loadingServer[@prev.split("/")[2]]
        count.loading--
        status = if res.status is "success" then "success" else "error"
        count[status]++

      if count.all is count.success + count.error
        #更新完了
        #ソート後にブックマークが更新されてしまう場合に備えて、少し待つ
        setTimeout(->
          $view
            .find(".table_sort_desc, .table_sort_asc")
              .removeClass("table_sort_desc table_sort_asc")
          for tr in $view[0].querySelectorAll("tr:not(.updated)")
            tr.parentNode.appendChild(tr)
          trUpdatedObserver.disconnect()
          $view.removeClass("loading")
          $view.find(".searchbox").prop("disabled", false)
          setTimeout(->
            $reload_button.removeClass("disabled")
          , 1000 * 10)
          return
        , 500)
      # 合計最大同時接続数: 2
      # 同一サーバーへの最大接続数: 1
      else if count.loading < 2
        for current, key in board_list
          server = current.split("/")[2]
          continue if loadingServer[server]
          loadingServer[server] = true
          board_list.splice(key, 1)
          count.loading++
          app.board.get(current, fn.bind(prev: current))
          fn()
          break

      #ステータス表示更新
      $loading_overlay.find(".success").text(count.success)
      $loading_overlay.find(".error").text(count.error)
      $loading_overlay.find(".loading").text(count.loading)
      $loading_overlay.find(".pending").text(count.all - count.success - count.error - count.loading)
      return

    fn()
    return

  threadList.addItem(
    for a in app.bookmark.get_all() when a.type is "thread"
      title: a.title
      url: a.url
      res_count: a.res_count or 0
      read_state: a.read_state or {url: a.url, read: 0, received: 0, last: 0}
      created_at: /\/(\d+)\/$/.exec(a.url)[1] * 1000
      expired: a.expired
  )

  app.message.send("request_update_read_state", {})
  $table.table_sort("update")

  $view.trigger("view_loaded")
  return
