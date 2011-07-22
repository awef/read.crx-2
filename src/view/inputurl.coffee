app.boot "/view/inputurl.html", ->
  $view = $(document.documentElement)

  app.view_module.reload($view)

  $view.find("form").bind "submit", ->
    url = this.url.value
    guess_res = app.url.guess_type(url)
    if guess_res.type is "thread" or guess_res.type is "board"
      if frameElement
        tmp = {type: "open", url: this.url.value}
        parent.postMessage(JSON.stringify(tmp), location.origin)
      else
        app.log("error", "view_input単体動作は未実装です")

      if frameElement
        tmp = {type: "request_killme"}
        parent.postMessage(JSON.stringify(tmp), location.origin)
      else
        chrome.tabs.getCurrent (tab) ->
          chrome.tabs.remove(tab.id)
    else
      $view
        .find(".notice")
          .hide()
          .text("未対応形式のURLです")
          .fadeIn("fast")
    return
