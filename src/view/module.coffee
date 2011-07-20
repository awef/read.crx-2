app.view_module = {}

app.view_module.open_in_rcrx = ($view) ->
  $view.delegate ".open_in_rcrx", "click", (e) ->
    e.preventDefault()
    url = this.href or this.getAttribute("data-href")
    if frameElement
      message = {type: "open", url}
      parent.postMessage(JSON.stringify(message), location.origin)
    else
      tmp = chrome.extension.getURL("/app.html?")
      tmp += app.url.build_param(q: url)
      open(tmp)

app.view_module.searchbox_thread_title = ($view, target_col) ->
  $view.find(".searchbox_thread_title")
    .bind "input", ->
      $view.find("table")
        .table_search("search", {query: this.value, target_col})
      return
    .bind "keyup", (e) ->
      if e.which is 27 #Esc
        this.value = ""
        $view.find("table").table_search("clear")
      return

app.view_module.bookmark_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_bookmark")
  if ///^http://\w///.test(url)
    if app.bookmark.get(url)
      $button.addClass("bookmarked")
    else
      $button.removeClass("bookmarked")

    on_update = (message) ->
      if message.bookmark.url is url
        if message.type is "added"
          $button.addClass("bookmarked")
        else if message.type is "removed"
          $button.removeClass("bookmarked")

    app.message.add_listener("bookmark_updated", on_update)

    $view.bind "view_unload", ->
      app.message.remove_listener("bookmark_updated", on_update)
      return

    $button.bind "click", ->
      if app.bookmark.get(url)
        app.bookmark.remove(url)
      else
        app.bookmark.add(url, $view.attr("data-title") or url)
      return
  else
    $button.remove()

app.view_module.link_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_link")
  if ///^http://\w///.test(url)
    $("<a>", href: app.safe_href(url), target: "_blank")
      .appendTo($button)
  else
    $button.remove()

app.view_module.reload_button = ($view) ->
  $view.find(".button_reload").bind "click", ->
    if not $(this).hasClass("disabled")
      $view.trigger("request_reload")
    return

app.view_module.board_contextmenu = ($view) ->
  $view
    #コンテキストメニュー 表示
    .delegate "tbody tr", "click, contextmenu", (e) ->
      if e.type is "contextmenu"
        e.preventDefault()

      app.defer =>
        $menu = $("#template > .view_module_board_contextmenu")
          .clone()
            .data("contextmenu_source", this)
            .appendTo($view)

        url = this.getAttribute("data-href")
        if app.bookmark.get(url)
          $menu.find(".add_bookmark").remove()
        else
          $menu.find(".del_bookmark").remove()

        $.contextmenu($menu, e.clientX, e.clientY)

      return

    #コンテキストメニュー 項目クリック
    .delegate ".view_module_board_contextmenu > *", "click", ->
      $this = $(this)
      $tr = $($this.parent().data("contextmenu_source"))

      url = $tr.attr("data-href")
      if $view.is(".view_bookmark")
        title = $tr.find("td:nth-child(1)").text()
        res_count = +$tr.find("td:nth-child(2)").text()
      else if $view.is(".view_board")
        title = $tr.find("td:nth-child(2)").text()
        res_count = +$tr.find("td:nth-child(3)").text()
      else
        app.log("error", "app.view_module.board_contextmenu: 想定外の状況で呼び出されました")

      if $this.hasClass("add_bookmark")
        app.bookmark.add(url, title, res_count)
      else if $this.hasClass("del_bookmark")
        app.bookmark.remove(url)

      $this.parent().remove()
      return
