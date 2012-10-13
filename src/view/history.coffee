app.boot "/view/history.html", ->
  $view = $(document.documentElement)

  app.view_module.view($view)

  $table = $("<table>")
  threadList = new UI.ThreadList($table[0], {
    th: ["title", "viewedDate"]
    searchbox: $view.find(".searchbox")[0]
  })
  $table.appendTo(".content")

  load = ->
    return if $view.hasClass("loading")
    return if $view.find(".button_reload").hasClass("disabled")

    $view.addClass("loading")

    app.History.get(undefined, 500).done (data) ->
      threadList.empty()
      threadList.addItem(data)
      $view.removeClass("loading")
      $view.trigger("view_loaded")
      $view.find(".button_reload").addClass("disabled")
      setTimeout(->
        $view.find(".button_reload").removeClass("disabled")
        return
      , 5000)
      return
    return

  $view.on("request_reload", load)
  load()
  return
