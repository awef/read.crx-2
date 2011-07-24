app.boot "/view/inputurl.html", ->
  $view = $(document.documentElement)

  app.view_module.view($view)
  app.view_module.reload($view)

  $view.find("form").bind "submit", ->
    url = this.url.value
    guess_res = app.url.guess_type(url)
    if guess_res.type is "thread" or guess_res.type is "board"
      app.message.send("open", url: this.url.value)

      tmp = {type: "request_killme"}
      parent.postMessage(JSON.stringify(tmp), location.origin)
    else
      $view
        .find(".notice")
          .hide()
          .text("未対応形式のURLです")
          .fadeIn("fast")
    return
