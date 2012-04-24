app.view_module = {}

app.view_module.view = ($view) ->
  #テーマ適用
  $view.addClass("theme_#{app.config.get("theme_id")}")
  app.message.add_listener "config_updated", (message) ->
    if message.key is "theme_id"
      $view.removeClass("theme_default theme_dark")
      $view.addClass("theme_#{message.val}")
    return

  #ユーザーCSS挿入
  do ->
    if $view.is(".view_index, .view_sidemenu, .view_bookmark, .view_board, .view_history, .view_inputurl, .view_thread")
      style = document.createElement("style")
      style.textContent = app.config.get("user_css")
      document.head.appendChild(style)
    return

  #title_updatedメッセージ送出処理
  do ->
    send_title_updated = ->
      tmp =
        type: "title_updated"
        title: document.title
      parent.postMessage(JSON.stringify(tmp), location.origin)

    if document.title
      send_title_updated()
    $view
      .find("title")
        .bind("DOMSubtreeModified", send_title_updated)

  #.open_in_rcrx
  $view
    #windowsのオートスクロール対策
    .on "mousedown", ".open_in_rcrx", (e) ->
      if e.which is 2
        e.preventDefault()
      return
    .on "click", ".open_in_rcrx", (e) ->
      e.preventDefault()
      url = @href or @getAttribute("data-href")
      title = @getAttribute("data-title") or @textContent
      how_to_open = app.util.get_how_to_open(e)
      new_tab = app.config.get("always_new_tab") is "on"
      new_tab or= how_to_open.new_tab or how_to_open.new_window
      background = how_to_open.background
      if frameElement
        app.message.send("open", {url, new_tab, background, title})
      else
        tmp = chrome.extension.getURL("/view/index.html?")
        tmp += app.url.build_param(q: url)
        open(tmp)
      return

  #unloadイベント → view_unloadイベント
  window.addEventListener "unload", ->
    $view.trigger("view_unload")

  window.addEventListener "message", (e) ->
    if e.origin is location.origin
      message = JSON.parse(e.data)
      #request_reload(postMessage) -> request_reload(event) 翻訳処理
      if message.type is "request_reload"
        if message.force_update is true
          $view.trigger("request_reload", force_update: true)
        else
          $view.trigger("request_reload")
      #tab_selected(postMessage) -> tab_selected(event) 翻訳処理
      else if message.type is "tab_selected"
        $view.trigger("tab_selected")

  #更新系のキーが押された場合の処理
  $(window)
    .bind "keydown", (e)->
      if e.which is 116 or (e.ctrlKey and e.which is 82) #F5 or Ctrl+R
        e.preventDefault()
        $view.trigger("request_reload")

  $view
    #mousedown通知
    .bind "mousedown", ->
      tmp = JSON.stringify(type: "view_mousedown")
      parent.postMessage(tmp, location.origin)

    #view_loaded翻訳処理
    .bind "view_loaded", ->
      tmp = JSON.stringify(type: "view_loaded")
      parent.postMessage(tmp, location.origin)

    #view内リロードボタンの処理
    .find(".button_reload")
      .bind "click", ->
        if not $(this).hasClass("disabled")
          $view.trigger("request_reload")
        return

app.view_module.searchbox_thread_title = ($view, target_col) ->
  $view
    .on "request_reload", ->
      $view.find(".searchbox_thread_title").val("").triggerHandler("input")
      return
    .find(".searchbox_thread_title")
      .on "input", ->
        if @value isnt ""
          $view
            .find("table")
              .table_search("search", {query: @value, target_col})
        else
          $view.find("table").table_search("clear")
        return
      .on "keyup", (e) ->
        if e.which is 27 #Esc
          @value = ""
          $(@).triggerHandler("input")
        return
  return

app.view_module.bookmark_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_bookmark")
  if ///^http://\w///.test(url)
    if app.bookmark.get(url)
      $button.addClass("bookmarked")
    else
      $button.removeClass("bookmarked")

    app.message.add_listener "bookmark_updated", (message) ->
      if message.bookmark.url is url
        if message.type is "added"
          $button.addClass("bookmarked")
        else if message.type is "removed"
          $button.removeClass("bookmarked")

    $button.bind "click", ->
      if app.bookmark.get(url)
        app.bookmark.remove(url)
      else
        app.bookmark.add(url, $view.find("title").text() or url)
      return
  else
    $button.remove()

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
      else if $view.is(".view_search")
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

app.view_module.sort_item_selector = ($view) ->
  $table = $(".table_sort")
  $selector = $view.find(".sort_item_selector")
  $table
    .on "table_sort_updated", (e, ex) ->
      $selector
        .find("option")
          .filter(->
            String(ex.sort_attribute or ex.sort_index) is @textContent
          )
            .attr("selected", true)
      return
  $selector
    .on "change", ->
      selected = @children[@selectedIndex]
      config = {}

      config.sort_order = selected.getAttribute("data-sort_order") or "desc"

      if /^\d+$/.test(@value)
        config.sort_index = +@value
      else
        config.sort_attribute = @value

      if (tmp = selected.getAttribute("data-sort_type"))?
        config.sort_type = tmp

      $table.table_sort("update", config)
      return
  return

app.view_module.tool_menu = ($view) ->
  copy = (str) ->
    input = document.createElement("input")
    input.value = str
    document.body.appendChild(input)
    input.select()
    document.execCommand("copy")
    document.body.removeChild(input)
    return

  # 項目クリック時にメニューを隠す
  $view.find(".button_tool > ul").on "click", ->
    app.defer =>
      $(@).css("display", "none")
      app.defer =>
        $(@).css("display", "")
        return
      return
    return

  # Chromeで直接開く
  do ->
    url = $view.attr("data-url")

    if url is "bookmark"
      url = "chrome-extension://eemcgdkfndhakfknompkggombfjjjeno/"
      url += "main.html##{app.config.get("bookmark_id")}"
    else
      url = app.safe_href(url)

    $view.find(".button_link > a").attr("href", url)
    return

  # タイトルをコピー
  $view.find(".button_copy_title").on "click", ->
    copy(document.title)
    return

  # URLをコピー
  $view.find(".button_copy_url").on "click", ->
    copy($view.attr("data-url"))
    return

  return
