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
  app.view_module.board_contextmenu($view)

  document.title = "検索:#{query}"
  app.history.add($view.attr("data-url"), document.title, opened_at)

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
    return

  $view.find(".more").on("click", load)
  load()
  return
