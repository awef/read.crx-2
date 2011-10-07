app.boot "/view/index.html", ->
  arg = app.url.parse_query(location.href)
  query = arg.q

  chrome.tabs.getCurrent (current_tab) ->
    chrome.windows.getAll {populate: true}, (windows) ->
      app_path = chrome.extension.getURL("/view/index.html")
      for win in windows
        for tab in win.tabs
          if tab.id isnt current_tab.id and tab.url is app_path
            chrome.windows.update(win.id, focused: true)
            chrome.tabs.update(tab.id, selected: true)
            if query
              chrome.tabs.sendRequest(tab.id, {type: "open", query})
            chrome.tabs.remove(current_tab.id)
            return
      history.pushState(null, null, "/view/index.html")
      app.main()
      if query
        app.message.send("open", url: query)

# #app.notice
app.notice = {}
app.notice.push = (text) ->
  $("<div>")
    .append(
      $("<div>", {text}),
      $("<button>")
        .bind "click", ->
          $(this)
            .parent()
            .animate({opacity: 0}, "fast")
            .delay("fast")
            .slideUp("fast", -> $(this).remove())
          return
      )
    .hide()
    .appendTo("#app_notice_container")
    .fadeIn()

# #app.view_tab_state
# タブの状態の保存/復元を行う
app.view_tab_state = {}

app.view_tab_state._get = ->
  data = []

  tmp = Array::slice.apply(document.getElementsByClassName("tab_content"))

  for tab_content in tmp
    tab_url = tab_content.getAttribute("data-url")
    tab_title = tab_content.getAttribute("data-title")

    data.push
      url: tab_url
      title: tab_title

    null

  data

# ##app.view_tab_state.store
# 現在の全てのタブのURLとタイトルを保存  
# unload時に使用出来るよう、非同期処理は用いてはいけない
app.view_tab_state.store = ->
  localStorage["tab_state"] = JSON.stringify(app.view_tab_state._get())

# ##app.view_tab_state.restore
# 保存されていたタブを復元
app.view_tab_state.restore = ->
  is_restored = false

  if localStorage["tab_state"]
    for tab in JSON.parse(localStorage["tab_state"])
      is_restored = true
      app.message.send("open", url: tab.url, title: tab.title, lazy: true)

  is_restored

app.view_setup_resizer = ->
  MIN_TAB_HEIGHT = 100

  $body = $("#body")

  if $body.hasClass("pane-3")
    val = "height"
    val_c = "Height"
    val_axis = "Y"
  else if $body.hasClass("pane-3h")
    val = "width"
    val_c = "Width"
    val_axis = "X"
  else
    app.log("warn", "呼ばれるべきでない状況でapp.view_setup_resizerが呼ばれました")
    return

  $tab_a = $("#tab_a")
  tab_a = $tab_a[0]
  offset = $tab_a["outer#{val_c}"]() - $tab_a[val]()

  min = MIN_TAB_HEIGHT
  max = document.body["offset#{val_c}"] - MIN_TAB_HEIGHT

  tmp = app.config.get("tab_a_#{val}")
  if tmp
    tab_a.style[val] =
      Math.max(Math.min(tmp - offset, max), min) + "px"

  $("#tab_resizer")
    .bind "mousedown", (e) ->
      that = this
      e.preventDefault()

      min = MIN_TAB_HEIGHT
      max = document.body["offset#{val_c}"] - MIN_TAB_HEIGHT

      $("<div>", {css: {
        position: "absolute"
        left: 0
        top: 0
        width: "100%"
        height: "100%"
        "z-index": 999
        cursor: if val_axis is "X" then "col-resize" else "row-resize"
      }})
        .bind "mousemove", (e) ->
          offset = that.parentNode[if val_axis is "Y" then "offsetTop" else "offsetLeft"]
          tab_a.style[val] =
            Math.max(Math.min(e["page#{val_axis}"] - offset, max), min) + "px"
          return

        .bind "mouseup", ->
          $(this).remove()
          app.config.set("tab_a_#{val}", parseInt(tab_a.style[val], 10))
          return

        .appendTo("body")
      return

app.main = ->
  $view = $(document.documentElement)

  app.view_module.view($view)

  document.title = app.manifest.name

  app.message.add_listener "notify", (message) ->
    app.notice.push(message.message)

  #タブ・ペインセットアップ
  layout = app.config.get("layout") or "pane-3"

  if layout is "pane-3"
    $("#body").addClass("pane-3")
    $("#tab_a, #tab_b").tab()
    $(".tab .tab_tabbar").sortable()
    app.view_setup_resizer()

  else if layout is "pane-3h"
    $("#body").addClass("pane-3h")
    $("#tab_a, #tab_b").tab()
    $(".tab .tab_tabbar").sortable()
    app.view_setup_resizer()

  else if layout is "pane-2"
    $("#body").addClass("pane-2")
    $("#tab_a").tab()
    $("#tab_b, #tab_resizer").remove()
    $(".tab .tab_tabbar").sortable()

  #タブの状態の保存/復元関連
  is_restored = app.view_tab_state.restore()
  window.addEventListener "unload", ->
    app.view_tab_state.store()
    return

  #もし、タブが一つも復元されなかったらブックマークタブを開く
  unless is_restored
    app.message.send("open", url: "bookmark")

  #openメッセージ受信部
  app.message.add_listener "open", (message) ->
    $iframe = $view
      .find("iframe[data-url=\"#{app.url.fix(message.url)}\"]")

    get_iframe_info = (url) ->
      guess_result = app.url.guess_type(url)
      if url is "config"
        src: "/view/config.html"
        url: "config"
        modal: true
      else if url is "history"
        src: "/view/history.html"
        url: "history"
      else if url is "bookmark"
        src: "/view/bookmark.html"
        url: "bookmark"
      else if url is "inputurl"
        src: "/view/inputurl.html"
        url: "inputurl"
      else if url is "bookmark_source_selector"
        src: "/view/bookmark_source_selector.html"
        url: "bookmark_source_selector"
        modal: true
      else if guess_result.type is "board"
        src: "/view/board.html?#{app.url.build_param(q: message.url)}"
        url: app.url.fix(message.url)
      else if guess_result.type is "thread"
        src: "/view/thread.html?#{app.url.build_param(q: message.url)}"
        url: app.url.fix(message.url)
      else
        null

    if $iframe.length is 1
      if $iframe.hasClass("tab_content")
        $iframe
          .closest(".tab")
            .tab("select", tab_id: $iframe.attr("data-tab_id"))
    else if iframe_info = get_iframe_info(message.url)
      lazy = message.lazy and (not message.modal)

      $iframe = $("<iframe>")
        .attr("src", if lazy then "/view/empty.html" else  iframe_info.src)
        .attr("data-url", iframe_info.url)
        .attr("data-title", message.title or iframe_info.url)

      if iframe_info.modal
        $iframe.appendTo("#modal")
      else
        target = "#tab_a"
        if iframe_info.src[0..16] is "/view/thread.html"
          target = document.getElementById("tab_b") or target

        $(target)
          .tab("add", {
            element: $iframe[0],
            title: $iframe.attr("data-title"),
            background: lazy
          })

        if lazy
          if $iframe.hasClass("tab_selected")
            $iframe.attr("src", get_iframe_info($iframe.attr("data-url")).src)
          else
            $iframe.one "tab_selected", ->
              $this = $(@)
              $this.attr("src", get_iframe_info($this.attr("data-url")).src)

  #初回スキャンに失敗した場合、タイミングの問題でopenメッセージを取得できな
  #いので、promiseを見てview_bookmark_source_selectorを呼び出す
  app.bookmark.promise_first_scan.fail ->
    app.message.send("open", url: "bookmark_source_selector")

  #openリクエストの監視
  chrome.extension.onRequest.addListener (request) ->
    if request.type is "open"
      app.message.send("open", url: request.query)

  #書き込み完了メッセージの監視
  chrome.extension.onRequest.addListener (request) ->
    if request.type is "written"
      iframe = document.querySelector("iframe[data-url=\"#{request.url}\"]")
      if iframe
        tmp = JSON.stringify(type: "request_reload", force_update: true)
        iframe.contentWindow.postMessage(tmp, location.origin)

  #viewからのメッセージを監視
  window.addEventListener "message", (e) ->
    if e.origin isnt location.origin
      return

    message = JSON.parse(e.data)

    for iframe in document.getElementsByTagName("iframe")
      if iframe.contentWindow is e.source
        $iframe = $(iframe)
        break

    if not $iframe?
      return

    switch message.type
      #タブ内コンテンツがtitle_updatedを送出した場合、タブのタイトルを更新
      when "title_updated"
        $iframe
          .closest(".tab")
            .tab("update_title", {
              tab_id: $iframe.attr("data-tab_id")
              title: message.title
            })

      #request_killmeの処理
      when "request_killme"
        #タブ内のviewが送ってきた場合
        if $iframe.hasClass("tab_content")
          $iframe
            .closest(".tab")
              .tab("remove", tab_id: $iframe.attr("data-tab_id"))
        #モーダルのviewが送ってきた場合
        else if $iframe.is("#modal > iframe")
          $iframe.fadeOut "fast", ->
            $iframe.remove()

      #view_loadedの翻訳
      when "view_loaded"
        $iframe.trigger("view_loaded")

      #view_mousedownの翻訳
      when "view_mousedown"
        $iframe.trigger("view_mousedown")

    return

  $view
    .bind "request_reload", ->
      iframe = document.querySelector("iframe.tab_focused")
      if iframe
        iframe.contentWindow.postMessage(
          JSON.stringify(type: "request_reload"), location.origin
        )

  $(window)
    #データ保存等の後片付けを行なってくれるzombie.html起動
    .bind "unload", ->
      if localStorage.zombie_read_state?
        open("/zombie.html", undefined, "left=1,top=1,width=250,height=50")
      return

  $(document.documentElement)
    #tab_selected(event) -> tab_selected(postMessage) 翻訳処理
    .delegate "iframe.tab_content", "tab_selected", ->
      tmp = JSON.stringify(type: "tab_selected")
      this.contentWindow.postMessage(tmp, location.origin)

    #タブの内容がクリックされた時にフォーカスを移動
    .delegate ".tab_content", "view_mousedown", ->
      if not this.classList.contains("tab_focused")
        $(".tab_focused")
          .removeClass("tab_focused")

        $(this)
          .closest(".tab")
            .find(".tab_selected")
              .addClass("tab_focused")
              .filter("iframe")
                .contents()
                  .find(".content")
                    .focus()
      return

    #タブが選択された時にフォーカスを移動
    .delegate ".tab_content", "tab_selected", ->
      $iframe = $(this)
      $(".tab_focused").removeClass("tab_focused")
      $iframe.closest(".tab").find(".tab_selected").addClass("tab_focused")
      #クリックでタブを選択した時にフォーカスが移らなくなるため、deferで飛ばす
      app.defer =>
        $iframe.contents().find(".content").focus()
      return

    #フォーカスしているタブが削除された時にフォーカスを移動
    .delegate ".tab_content", "tab_removed", ->
      $tmp = $(this).closest(".tab").find(".tab_selected")
      if $tmp.filter(".tab_content").is(this)
        app.defer ->
          $(".tab:has(.tab_selected):first")
            .find(".tab_selected")
              .addClass("tab_focused")
              .filter("iframe")
                .contents()
                  .find(".content")
                    .focus()
      return

    #フォーカスしているタブ内のコンテンツが再描画された場合、フォーカスを合わせ直す
    .delegate ".tab_content", "view_loaded", ->
      $iframe = $(this)
      if $iframe.hasClass("tab_focused")
        $iframe.contents().find(".content").focus()
      return
