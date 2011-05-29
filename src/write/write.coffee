app = {}

#TODO バージョン互換性確保処理

$ ->
  $view = $(".view_write")

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
    console.log e.data
    if message.type is "ping"
      e.source.postMessage("write_iframe_pong", "*")
    else if message.type is "success"
      $view.find(".cancel").attr("disabled", true)
      #TODO 書き込み完了メッセージ送出
      $view.find(".notice").text("書き込み成功")
      setTimeout ->
        chrome.tabs.getCurrent (tab) ->
          chrome.tabs.remove(tab.id)
      , 2000
    else if message.type is "confirm"
      $view.find(".iframe_container").fadeIn("fast")
    else if message.type is "error"
      on_error(data.message)

  $view.find(".cancel, .hide_iframe").bind "click", ->
    $view.find(".iframe_container").find("iframe").remove().end().fadeOut("fast")
    $view.find("form input, form textarea").removeAttr("disabled")
    $view.find(".cacnel").attr("disabled", true)
    $view.find(".notice").text("")

  arg = app.url.parse_query(location.href)
  arg.url = app.url.fix(arg.url)
  arg.title or= arg.url
  arg.name or= ""
  arg.mail or= ""
  arg.message or= ""

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
      iframe_url = app.url.fix(arg.url) + "1?"
      iframe_url += app.url.build_param(iframe_arg)

      $("<iframe>")
        .attr("src", iframe_url)
        .appendTo($view.find(".iframe_container"))

      $view.find(".notice").text("書き込み中")
