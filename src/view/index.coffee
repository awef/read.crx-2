app.boot "/view/index.html", ->
  arg = app.url.parse_query(location.href)
  query = arg.q

  get_current = $.Deferred (deferred) ->
    chrome.tabs.getCurrent (current_tab) ->
      deferred.resolve(current_tab)

  get_all = $.Deferred (deferred) ->
    chrome.windows.getAll {populate: true}, (windows) ->
      deferred.resolve(windows)

  $.when(get_current, get_all)
    .done (current_tab, windows) ->
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
      history.replaceState(null, null, "/view/index.html")
      app.main()
      if query
        app.message.send("open", url: query, new_tab: true)

app.view_setup_resizer = ->
  MIN_TAB_HEIGHT = 100

  $body = $("#body")

  $tab_a = $("#tab_a")
  tab_a = $tab_a[0]

  right_pane = document.getElementById("right_pane")

  val = null
  val_c = null
  val_axis = null
  min = null
  max = null
  offset = null

  update_info = ->
    if $body.hasClass("pane-3")
      val = "height"
      val_c = "Height"
      val_axis = "Y"
      offset = right_pane.offsetTop
    else if $body.hasClass("pane-3h")
      val = "width"
      val_c = "Width"
      val_axis = "X"
      offset = right_pane.offsetLeft
    min = MIN_TAB_HEIGHT
    max = right_pane["offset#{val_c}"] - MIN_TAB_HEIGHT
    return

  update_info()

  tmp = app.config.get("tab_a_#{val}")
  if tmp
    tab_a.style[val] = Math.max(Math.min(tmp, max), min) + "px"

  $("#tab_resizer")
    .on "mousedown", (e) ->
      e.preventDefault()

      update_info()

      $("<div>", {css: {
        position: "absolute"
        left: 0
        top: 0
        width: "100%"
        height: "100%"
        "z-index": 999
        cursor: if val_axis is "X" then "col-resize" else "row-resize"
      }})
        .on "mousemove", (e) =>
          tab_a.style[val] =
            Math.max(Math.min(e["page#{val_axis}"] - offset, max), min) + "px"
          return

        .on "mouseup", ->
          $(@).remove()
          app.config.set("tab_a_#{val}", parseInt(tab_a.style[val], 10))
          return

        .appendTo("body")
      return

app.main = ->
  urlToIframeInfo = (url) ->
    url = app.url.fix(url)
    guessResult = app.url.guess_type(url)
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
    else if res = /^search:(.+)$/.exec(url)
      src: "/view/search.html?#{app.url.build_param(query: res[1])}"
      url: url
    else if guessResult.type is "board"
      src: "/view/board.html?#{app.url.build_param(q: url)}"
      url: url
    else if guessResult.type is "thread"
      src: "/view/thread.html?#{app.url.build_param(q: url)}"
      url: url
    else
      null

  iframeSrcToUrl = (src) ->
    if res = ///^/view/(\w+)\.html$///.exec(src)
      res[1]
    else if res = ///^/view/search\.html(\?.+)$///.exec(src)
      app.url.parse_query(res[1]).query
    else if res = ///^/view/(?:thread|board)\.html(\?.+)$///.exec(src)
      app.url.parse_query(res[1]).q
    else
      null

  $view = $(document.documentElement)

  app.view_module.view($view)

  document.title = app.manifest.name

  app.Ninja.enableAutoBackup()

  app.message.add_listener "notify", (message) ->
    text = message.message
    html = message.html
    background_color = message.background_color or "#777"
    $("<div>")
      .css("background-color", background_color)
      .append(
        (if html? then $("<div>", {html}) else $("<div>", {text}))
        $("<div>")
      )
      .one "click", "a, div:last-child", (e) ->
        $(e.delegateTarget)
          .animate({opacity: 0}, "fast")
          .delay("fast")
          .slideUp("fast", -> $(@).remove())
        return
      .hide()
      .appendTo("#app_notice_container")
      .fadeIn()

  #前回起動時のバージョンと違うバージョンだった場合、アップデート通知を送出
  do ->
    last_version = app.config.get("last_version")
    if last_version?
      if app.manifest.version isnt last_version
        app.message.send "notify", {
          html: """
            #{app.manifest.name} が #{last_version} から
             #{app.manifest.version} にアップデートされました。
             <a href="http://idawef.com/read.crx-2/changelog.html" target="_blank">更新履歴</a>
          """
          background_color: "green"
        }
      else
        return
    app.config.set("last_version", app.manifest.version)

  #タブ・ペインセットアップ
  $("#body").addClass(app.config.get("layout"))
  tabA = new UI.Tab(document.querySelector("#tab_a"))
  $("#tab_a").data("tab", tabA)
  tabB = new UI.Tab(document.querySelector("#tab_b"))
  $("#tab_b").data("tab", tabB)
  $(".tab .tab_tabbar").sortable(exclude: "img")
  app.view_setup_resizer()

  $view.on "tab_urlupdated", "iframe", ->
    @setAttribute("data-url", iframeSrcToUrl(@getAttribute("src")))
    return

  app.message.add_listener "config_updated", (message) ->
    if message.key is "layout"
      $("#body")
        .removeClass("pane-3 pane-3h pane-2")
        .addClass(message.val)
      $("#tab_a, #tab_b").css(width: "", height: "")
      #タブ移動
      #2->3
      if message.val is "pane-3" or message.val is "pane-3h"
        for tmp in tabA.getAll()
          iframe = document.querySelector("iframe[data-tabid=\"#{tmp.tabId}\"]")
          tmpURL = iframe.getAttribute("data-url")

          if app.url.guess_type(tmpURL).type is "thread"
            app.message.send "open", {
                new_tab: true
                lazy: true
                url: tmpURL
                title: tmp.title
              }
            tabA.remove(tmp.tabId)
      #3->2
      if message.val is "pane-2"
        for tmp in tabB.getAll()
          iframe = document.querySelector("iframe[data-tabid=\"#{tmp.tabId}\"]")
          tmpURL = iframe.getAttribute("data-url")

          app.message.send "open", {
              new_tab: true
              lazy: true
              url: tmpURL
              title: tmp.title
            }
          tabB.remove(tmp.tabId)
    return

  # #13対策
  $view
    .find(".tab_tabbar")
      .on("mouseenter", "li", -> @classList.add("hover"))
      .on("mouseleave", "li", -> @classList.remove("hover"))

  #タブ復元
  if localStorage.tab_state?
    for tab in JSON.parse(localStorage.tab_state)
      is_restored = true
      app.message.send("open", {
        url: tab.url
        title: tab.title
        lazy: not tab.selected
        new_tab: true
      })

  #もし、タブが一つも復元されなかったらブックマークタブを開く
  unless is_restored
    app.message.send("open", url: "bookmark")

  #終了時にタブの状態を保存する
  window.addEventListener "unload", ->
    data = for tab in tabA.getAll().concat(tabB.getAll())
      url: document.querySelector("iframe[data-tabid=\"#{tab.tabId}\"]").getAttribute("data-url")
      title: tab.title
      selected: tab.selected
    localStorage.tab_state = JSON.stringify(data)
    return

  #openメッセージ受信部
  app.message.add_listener "open", (message) ->
    iframe_info = urlToIframeInfo(message.url)
    return unless iframe_info

    if iframe_info.modal
      unless $view.find("iframe[src=\"#{iframe_info.src}\"]").length
        $("<iframe>")
          .attr("src", iframe_info.src)
          .attr("data-url", iframe_info.url)
          .attr("data-title", message.title or iframe_info.url)
          .appendTo("#modal")
    else
      $li = $view.find(".tab_tabbar > li[data-tabsrc=\"#{iframe_info.src}\"]")
      if $li.length
        $li.closest(".tab").data("tab").update($li.attr("data-tabid"), selected: true)
        if message.url isnt "bookmark" #ブックマーク更新は時間がかかるので例外扱い
          tmp = JSON.stringify(type: "request_reload")
          $iframe = $view.find("iframe[data-tabid=\"#{$li.attr("data-tabid")}\"]")
          $iframe[0].contentWindow.postMessage(tmp, location.origin)
      else
        target = tabA
        if iframe_info.src[0..16] is "/view/thread.html" and
            not $("#body").hasClass("pane-2")
          target = tabB

        if message.new_tab or not (selectedTab = target.getSelected())
          tabId = target.add(iframe_info.src, {
            title: message.title or iframe_info.url
            selected: not (message.background or message.lazy)
            lazy: message.lazy
          })
        else
          tabId = selectedTab.tabId
          target.update(tabId, {
            url: iframe_info.src
            title: message.title or iframe_info.url
            selected: true
          })
        $view
          .find("iframe[data-tabid=\"#{tabId}\"]")
            .attr("data-url", iframe_info.url)
    return

  #初回スキャンに失敗した場合、タイミングの問題でopenメッセージを取得できな
  #いので、promiseを見てview_bookmark_source_selectorを呼び出す
  app.bookmark.promise_first_scan.fail ->
    app.message.send("open", url: "bookmark_source_selector")

  #openリクエストの監視
  chrome.extension.onRequest.addListener (request) ->
    if request.type is "open"
      app.message.send("open", url: request.query, new_tab: true)

  #書き込み完了メッセージの監視
  chrome.extension.onRequest.addListener (request) ->
    if request.type in ["written", "written?"]
      iframe = document.querySelector("iframe[data-url=\"#{request.url}\"]")
      if iframe
        tmp = JSON.stringify(type: "request_reload", force_update: true)
        iframe.contentWindow.postMessage(tmp, location.origin)

  #viewからのメッセージを監視
  window.addEventListener "message", (e) ->
    return if e.origin isnt location.origin

    $iframe = $(e.source.frameElement)
    return if $iframe.length isnt 1

    message = JSON.parse(e.data)

    switch message.type
      #タブ内コンテンツがtitle_updatedを送出した場合、タブのタイトルを更新
      when "title_updated"
        if $iframe.hasClass("tab_content")
          $iframe
            .closest(".tab")
              .data("tab")
                .update($iframe.attr("data-tabid"), title: message.title)

      #request_killmeの処理
      when "request_killme"
        #タブ内のviewが送ってきた場合
        if $iframe.hasClass("tab_content")
          $iframe
            .closest(".tab")
              .data("tab")
                .remove($iframe.attr("data-tabid"))
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
    .on "tab_removed tab_beforeurlupdate", "iframe", ->
      @contentWindow.___e = @contentDocument.createEvent("Event")
      @contentWindow.___e.initEvent("view_unload", true, true)
      @contentWindow.dispatchEvent(@contentWindow.___e)
      return

    #tab_selected(event) -> tab_selected(postMessage) 翻訳処理
    .delegate "iframe.tab_content", "tab_selected", ->
      tmp = JSON.stringify(type: "tab_selected")
      @contentWindow.postMessage(tmp, location.origin)
      return

    #タブの内容がクリックされた時にフォーカスを移動
    .delegate ".tab_content:not(.tab_focused)", "view_mousedown", ->
      $(".tab_focused").removeClass("tab_focused")
      $(@)
        .closest(".tab")
          .find(".tab_selected")
            .addClass("tab_focused")
            .filter(".tab_content")
              .contents()
                .find(".content")
                  .focus()
      return

    #タブが選択された時にフォーカスを移動
    .delegate ".tab_content", "tab_selected", ->
      $iframe = $(@)
      $(".tab_focused").removeClass("tab_focused")
      $iframe.closest(".tab").find(".tab_selected").addClass("tab_focused")
      #クリックでタブを選択した時にフォーカスが移らなくなるため、deferで飛ばす
      app.defer =>
        $iframe.contents().find(".content").focus()
      return

    #フォーカスしているタブが削除された時にフォーカスを移動
    .on "tab_removed", ".tab_content", ->
      app.defer ->
        $tmp = $(".tab:has(.tab_selected):first")
        if $tmp.length is 1
          $tmp
            .find(".tab_selected")
              .addClass("tab_focused")
              .filter(".tab_content")
                .contents()
                  .find(".content")
                    .focus()
        else
          $("#left_pane").contents().find("[tabindex]").focus()
        return
      return

    #フォーカスしているタブ内のコンテンツが再描画された場合、フォーカスを合わせ直す
    .delegate ".tab_content.tab_focused", "view_loaded", ->
      $(@).contents().find(".content").focus()
      return

  #タブコンテキストメニュー
  $view.find(".tab_tabbar").on "contextmenu", (e) ->
    e.preventDefault()

    $source = $(e.target).closest(".tab_tabbar, li")
    $menu = $("#template > .tab_contextmenu").clone()

    if $source.is("li")
      sourceTabId = $source.attr("data-tabid")
    else
      $menu.children().not(".restore").remove()

    tab = $source.closest(".tab").data("tab")

    getLatestRestorableTabID = ->
      tabURLList = (a.url for a in tab.getAll())
      list = tab.getRecentClosed()
      list.reverse()
      for tmpTab in list
        if not (tmpTab.url in tabURLList)
          return tmpTab.tabId
      null

    if not getLatestRestorableTabID()
      $menu.find(".restore").remove()

    if $menu.children().length is 0
      return

    $menu.one "click", "li", ->
      $this = $(@)

      #閉じたタブを開く
      if $this.is(".restore")
        if tmp = getLatestRestorableTabID()
          tab.restoreClosed(tmp)
      #再読み込み
      else if $this.is(".reload")
        $view.find("iframe[data-tabid=\"#{sourceTabId}\"]")[0]
          .contentWindow.postMessage(
            JSON.stringify(type: "request_reload")
            location.origin
          )
      #タブを閉じる
      else if $this.is(".close")
        tab.remove(sourceTabId)
      #タブを全て閉じる
      else if $this.is(".close_all")
        $source.siblings().andSelf().each ->
          tab.remove($(@).attr("data-tabid"))
          return
      #他のタブを全て閉じる
      else if $this.is(".close_all_other")
        $source.siblings().each ->
          tab.remove($(@).attr("data-tabid"))
          return
      #右側のタブを全て閉じる
      else if $this.is(".close_right")
        $source.nextAll().each ->
          tab.remove($(@).attr("data-tabid"))
          return
      $menu.remove()
      return

    app.defer ->
      $menu.appendTo(document.body)
      $.contextmenu($menu, e.clientX, e.clientY)
      return
    return
  return
