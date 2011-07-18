app.main = ->
  $view = $(".view_write")

  arg = app.url.parse_query(location.href)
  arg.url = app.url.fix(arg.url)
  arg.title or= arg.url
  arg.name or= app.config.get("default_name") or ""
  arg.mail or= app.config.get("default_mail") or ""
  arg.message or= ""

  on_error = (message) ->
    $view.find("form input, form textarea").removeAttr("disabled")
    $view.find(".cancel").attr("disabled", true)

    if message
      $view.find(".notice").text("書き込み失敗 - #{message}")
    else
      $view.find(".notice").text("")
      $view.find(".iframe_container").fadeIn("fast")

  window.addEventListener "message", (e) ->
    message = JSON.parse(e.data)
    if message.type is "ping"
      e.source.postMessage("write_iframe_pong", "*")
    else if message.type is "success"
      $view.find(".cancel").attr("disabled", true)
      $view.find(".notice").text("書き込み成功")
      setTimeout ->
        chrome.extension.sendRequest(type: "written", url: arg.url)
        chrome.tabs.getCurrent (tab) ->
          chrome.tabs.remove(tab.id)
      , 2000
    else if message.type is "confirm"
      $view.find(".iframe_container").fadeIn("fast")
    else if message.type is "error"
      on_error(message.message)
    return

  $view.find(".cancel, .hide_iframe").bind "click", ->
    $view.find(".iframe_container").find("iframe").remove().end().fadeOut("fast")
    $view.find("form input, form textarea").removeAttr("disabled")
    $view.find(".cacnel").attr("disabled", true)
    $view.find(".notice").text("")
    return

  $view.find(".cancel, .hide_iframe").bind "click", ->
    $view
      .find(".iframe_container")
        .find("iframe")
          .remove()
        .end()
      .fadeOut("fast")
    $view.find("input, textarea").removeAttr("disabled")
    $view.find(".cancel").attr("disabled", true)
    $view.find(".notice").text("")
    return

  document.title = arg.title
  $view.find("h1").text(arg.title)
  $view.find(".name").val(arg.name)
  $view.find(".mail").val(arg.mail)
  $view.find(".message").val(arg.message)

  $view.find("form").bind "submit", (e) ->
    e.preventDefault()

    $view.find("input, textarea").attr("disabled", true)
    $view.find("#cancel").removeAttr("disabled")

    iframe_arg =
      rcrx_name: $view.find(".name").val()
      rcrx_mail: $view.find(".mail").val()
      rcrx_message: $view.find(".message").val()

    tmp = app.url.guess_type(arg.url)
    if (tmp.bbs_type is "2ch" and ///http://\w+\.2ch\.net/ ///.test(arg.url)) or tmp.bbs_type is "jbbs"
      if app.config.get("p2_write") is "on"
        if not /^w\d+\.p2\.2ch\.net$/.test(app.config.get("p2_server"))
          on_error("p2のサーバー設定が誤っています")
          return

        if res = ///^http://(\w+\.2ch\.net)/test/read\.cgi/(\w+)/(\d+)///.exec(arg.url)
          iframe_arg.host = res[1]
          iframe_arg.bbs = res[2]
          iframe_arg.key = res[3]
        else if res = ///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/(\w+)/(\d+)/(\d+)///.exec(arg.url)
          iframe_arg.host = "jbbs.livedoor.jp/#{res[1]}"
          iframe_arg.bbs = res[2]
          iframe_arg.key = res[3]

        iframe_url = "http://#{app.config.get("p2_server")}"
        iframe_url += "/p2/post_form.php?#{app.url.build_param(iframe_arg)}"

      else
        iframe_url = app.url.fix(arg.url) + "1?"
        iframe_url += app.url.build_param(iframe_arg)

      $("<iframe>")
        .attr("src", iframe_url)
        .appendTo($view.find(".iframe_container"))

      $view.find(".notice").text("書き込み中")
    return

app.boot "/write/write.html", ->
  $(app.main)

