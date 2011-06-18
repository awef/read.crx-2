(->
  if location.pathname isnt "/app.html"
    return

  xhr = new XMLHttpRequest()
  xhr.open("GET", "/manifest.json", false)
  xhr.send(null)
  app.manifest = JSON.parse(xhr.responseText)

  html_version = document.documentElement.getAttribute("data-app-version")
  if app.manifest.version isnt html_version
    location.reload(true)

  reg_res = /[\?&]q=([^&]+)/.exec(location.search)
  query = decodeURIComponent(reg_res?[1] or "bookmark")

  chrome.tabs.getCurrent (current_tab) ->
    chrome.windows.getAll {populate: true}, (windows) ->
      app_path = chrome.extension.getURL("app.html")
      for win in windows
        for tab in win.tabs
          if tab.id isnt current_tab.id and tab.url is app_path
            chrome.windows.update(win.id, focused: true)
            chrome.tabs.update(tab.id, selected: true)
            if query isnt "app"
              chrome.tabs.sendRequest(tab.id, {type: "open", query})
            chrome.tabs.remove(current_tab.id)
            return
      history.pushState(null, null, "/app.html")
      $ ->
        app.main()
        if query isnt "app"
          app.message.send("open", url: query)
)()

app.main = ->
  $("#left_pane").append(app.view_sidemenu.open())

  app.view_tab_state.restore()
  window.addEventListener "unload", ->
    app.view_tab_state.store()

  chrome.extension.onRequest.addListener (request) ->
    if request.type is "open"
      app.message.send("open", url: request.query)

  $("#body").addClass("pane-3")

  $("#tab_a, #tab_b").tab()
  $(".tab .tab_tabbar").sortable()

  app.view_setup_resizer()

  app.message.add_listener "open", (message) ->
    $container = $(".tab_container")
      .find("> [data-url=\"#{app.url.fix(message.url)}\"]")

    guess_result = app.url.guess_type(message.url)

    if $container.length is 1
      $container
        .closest(".tab")
          .tab("select", tab_id: $container.attr("data-tab_id"))
    else if message.url is "config"
      $view = app.view_config.open()
    else if message.url is "history"
      $view = app.view_history.open()
    else if message.url is "bookmark"
      $view = app.view_bookmark.open()
    else if guess_result.type is "board"
      $view = app.view_board.open(message.url)
    else if guess_result.type is "thread"
      $view = app.view_thread.open(message.url)

    if $view
      $(if guess_result.type is "thread" then "#tab_b" else "#tab_a")
        .tab("add", element: $view[0], title: $view.attr("data-title"))

  $(document.documentElement)
    .delegate ".open_in_rcrx", "click", (e) ->
      e.preventDefault()
      app.message.send "open",
        url: this.href or this.getAttribute("data-href")

  $(window).bind "keydown", (e) ->
    if e.which is 116 or (e.ctrlKey and e.which is 82) #F5 or Ctrl+R
      e.preventDefault()
      $(".tab .tab_container .tab_focused").trigger("request_reload")
