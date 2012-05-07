app.boot "/view/search.html", ["euc_jp_escape", "thread_search"], (euc_jp_escape, ThreadSearch) ->
  query = app.url.parse_query(location.href).query

  unless query?
    alert("不正な引数です")
    return

  opened_at = Date.now()

  $view = $(document.documentElement)
  $view.attr("data-url", "search:#{query}")

  $message_bar = $view.find(".message_bar")
  $button_reload = $view.find(".button_reload")

  app.view_module.view($view)
  app.view_module.board_contextmenu($view)
  app.view_module.tool_menu($view)

  document.title = "検索:#{query}"
  app.history.add($view.attr("data-url"), document.title, opened_at)

  euc_jp_escape.escape(query).done (q) ->
    $view.find(".button_link > a").attr("href", "http://find.2ch.net/index.php?BBS=2ch&TYPE=TITLE&SORT=CREATED&STR=" + q)
    return

  $table = $("<table>")
  $table.thread_list("create",
    th: ["bookmark", "title", "board_title", "res", "heat", "created_date"]
    searchbox: $view.find(".searchbox")
  )
  $table.prependTo(".content")

  thread_search = new ThreadSearch(query)
  tbody = $view.find("tbody")[0]

  load = ->
    return if $view.hasClass("loading")
    $view.addClass("loading")
    $button_reload.addClass("disabled")
    $view.find(".more").text("検索中")
    thread_search.read()
      .done (result) ->
        $message_bar.removeClass("error").empty()

        $table.thread_list("add_item", result)

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
      .always ->
        setTimeout((-> $button_reload.removeClass("disabled"); return), 5000)
        return
    return

  $button_reload.on "click", ->
    return if $button_reload.hasClass("disabled")
    $table.thread_list("empty")
    thread_search = new ThreadSearch(query)
    load()
    return

  $view.find(".more").on("click", load)
  load()
  return
