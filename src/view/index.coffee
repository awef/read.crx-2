app.boot "/view/index.html", ->
  reg_res = /[\?&]q=([^&]+)/.exec(location.search)
  query = decodeURIComponent(reg_res?[1] or "app")

  chrome.tabs.getCurrent (current_tab) ->
    chrome.windows.getAll {populate: true}, (windows) ->
      app_path = chrome.extension.getURL("/view/index.html")
      for win in windows
        for tab in win.tabs
          if tab.id isnt current_tab.id and tab.url is app_path
            chrome.windows.update(win.id, focused: true)
            chrome.tabs.update(tab.id, selected: true)
            if query isnt "app"
              chrome.tabs.sendRequest(tab.id, {type: "open", query})
            chrome.tabs.remove(current_tab.id)
            return
      history.pushState(null, null, "/view/index.html")
      app.main()
      if query isnt "app"
        app.message.send("open", url: query)

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
      app.message.send("open", url: tab.url)

  is_restored

app.view_setup_resizer = ->
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

  min = 50
  max = document.body["offset#{val_c}"] - 50

  tmp = app.config.get("tab_a_#{val}")
  if tmp
    tab_a.style[val] =
      Math.max(Math.min(tmp - offset, max), min) + "px"

  $("#tab_resizer")
    .bind "mousedown", (e) ->
      that = this
      e.preventDefault()

      min = 50
      max = document.body["offset#{val_c}"] - 50

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
  document.title = app.manifest.name

  #TODO サイドメニューのセットアップ
  #$("#left_pane").append(app.view_sidemenu.open())

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
    $iframe = $(".tab_container")
      .find("> [data-url=\"#{app.url.fix(message.url)}\"]")

    get_iframe_info = (url) ->
      guess_result = app.url.guess_type(url)
      if url is "config"
        src: "/view/config.html"
        url: "config"
      else if url is "history"
        src: "/view/history.html"
        url: "history"
      else if url is "bookmark"
        src: "/view/bookmark.html"
        url: "bookmark"
      else if url is "inputurl"
        src: "/view/inputurl.html"
        url: "inputurl"
      else if guess_result.type is "board"
        src: "/view/board.html?#{app.url.build_param(q: message.url)}"
        url: app.url.fix(message.url)
      else if guess_result.type is "thread"
        src: "/view/thread.html?#{app.url.build_param(q: message.url)}"
        url: app.url.fix(message.url)
      else
        null

    if $iframe.length is 1
      $iframe
        .closest(".tab")
          .tab("select", tab_id: $iframe.attr("data-tab_id"))
    else if iframe_info = get_iframe_info(message.url)
      $iframe = $("<iframe>")
        .attr("src", iframe_info.src)
        .attr("data-url", iframe_info.url)
        .attr("data-title", iframe_info.url)

      target = "#tab_a"
      if iframe_info.src[0..16] is "/view/thread.html"
        target = document.getElementById("tab_b") or target

      $(target)
        .tab("add", element: $iframe[0], title: $iframe.attr("data-title"))

  #openリクエストの監視
  chrome.extension.onRequest.addListener (request) ->
    if request.type is "open"
      app.message.send("open", url: request.query)

  #書き込み完了メッセージの監視
  chrome.extension.onRequest.addListener (request) ->
    if request.type is "written"
      $(".view_thread[data-url=\"#{request.url}\"]")
        .trigger("request_reload", force_update: true)

  #viewからのメッセージを監視
  window.addEventListener "message", (e) ->
    if e.origin isnt location.origin
      return

    message = JSON.parse(e.data)
    #タブ内コンテンツがopenを送出した場合、対応するviewを開く
    if message.type is "open"
      app.message.send("open", url: message.url)
    #タブ内コンテンツがtitle_updatedを送出した場合、タブのタイトルを更新する
    else if message.type is "title_updated"
      for iframe in document.querySelectorAll("iframe.tab_content")
        if iframe.contentWindow is e.source
          $iframe = $(iframe)
          $iframe.closest(".tab")
            .tab("update_title", {
              tab_id: $iframe.attr("data-tab_id")
              title: message.title
            })
          break
    return

  $(window)
    #更新系のキーが押された時の処理
    .bind "keydown", (e) ->
      if e.which is 116 or (e.ctrlKey and e.which is 82) #F5 or Ctrl+R
        e.preventDefault()
        #TODO
        #$(".tab .tab_container .tab_focused").trigger("request_reload")
      return

    #データ保存等の後片付けを行なってくれるzombie.html起動
    .bind "unload", ->
      if localStorage.zombie_read_state?
        open("/zombie.html", undefined, "left=1,top=1,width=250,height=50")
      return

  $(document.documentElement)
    #タブ内コンテンツがview_request_killmeを送って来た場合、タブを閉じる。
    .delegate ".tab_content", "view_request_killme", ->
      $this = $(this)
      $this.closest(".tab").tab("remove", tab_id: $this.attr("data-tab_id"))
      return

    #tab_removedイベントをview_unloadに翻訳
    .delegate ".tab_content", "tab_removed", ->
      $(this).trigger("view_unload")
      return

    #フォーカス管理
    #タブの内容がクリックされた時にフォーカスを移動
    .delegate ".tab_content", "mousedown", ->
      if not this.classList.contains("tab_focused")
        $(".tab_focused")
          .removeClass("tab_focused")

        $(this)
          .closest(".tab")
            .find(".tab_selected")
              .addClass("tab_focused")
              .find(".content")
                .focus()
      return

    #タブが選択された時にフォーカスを移動
    .delegate ".tab_content", "tab_selected", ->
      $(".tab_focused").removeClass("tab_focused")
      $(this).closest(".tab").find(".tab_selected").addClass("tab_focused")
      #クリックでタブを選択した時にフォーカスが移らなくなるため、deferで飛ばす
      app.defer ->
        $(".tab_focused .content").focus()
      return

    #フォーカスしているタブが削除された時にフォーカスを移動
    .delegate ".tab_content", "tab_removed", ->
      $tmp =  $(this).closest(".tab").find(".tab_selected")
      if $tmp.filter(".tab_content").is(this)
        app.defer ->
          $(".tab:has(.tab_selected):first")
            .find(".tab_selected")
              .addClass("tab_focused")
              .find(".content")
                .focus()
      return

    #フォーカスしているタブ内のコンテンツが再描画された場合、フォーカスを合わせ直す
    .delegate ".tab_content", "view_loaded", ->
      if this.classList.contains("tab_focused")
        this.getElementsByClassName("content")[0]?.focus()
      return
