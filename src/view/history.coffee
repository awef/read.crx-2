app.boot "/view/history.html", ["history"], (History) ->
  $view = $(document.documentElement)

  app.view_module.view($view)

  $table = $("<table>")
  $table.thread_list("create", th: ["title", "viewed_date"])
  $table.appendTo(".content")

  load = ->
    return if $view.hasClass("loading")
    return if $view.find(".button_reload").hasClass("disabled")

    $view.addClass("loading")

    History.get(undefined, 500).done (data) ->
      $table.thread_list("empty")
      $table.thread_list("add_item", data)
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
