(->
  if location.pathname isnt "/app.html"
    return

  xhr = new XMLHttpRequest()
  xhr.open("GET", "/manifest.json", false)
  xhr.send(null)
  manifest = JSON.parse(xhr.responseText)

  html_version = document.documentElement.getAttribute("data-app-version")
  if manifest.version isnt html_version
    location.reload(true)

  reg_res = /[\?&]q=([^&]+)/.exec(location.search)
  query = reg_res?[1] or "app"

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
          app.message.send("open", {query})
)()

`/** @namespace */`
app = {}

app.main = ->
  app.view.init()
  app.view.load_sidemenu()

  app.message.add_listener "open", (message) ->
    $container = $(".tab_container")
      .find("> [data-url=\"#{app.url.fix(message.url)}\"]")

    guess_result = app.url.guess_type(message.url)

    if $container.length is 1
      $container
        .closest(".tab")
          .tab("select", tab_id: $container.attr("data-tab_id"))
    else if message.url is "config"
      app.view.open_config()
    else if message.url is "history"
      app.view.open_history()
    else if message.url is "bookmark"
      app.view.open_bookmark()
    else if guess_result.type is "board"
      app.view.open_board(message.url)
    else if guess_result.type is "thread"
      app.view.open_thread(message.url)

  chrome.extension.onRequest.addListener (request) ->
    if request.type is "open"
      app.message.send("open", url: request.query)

app.log = (level) ->
  if ["log", "debug", "info", "warn", "error"].indexOf(level) isnt -1
    console[level].apply(console, Array.prototype.slice.call(arguments, 1))
  else
    app.log("error", "app.log: 引数levelが不正な値です", arguments)

app.deep_copy = (data) ->
  JSON.parse(JSON.stringify(data))

app.assert_arg = (name, rule, arg) ->
  for val, key in rule
    unless typeof arg[key] is val
      app.log("error", "#{name}: 不正な引数", app.deep_copy(arg))
      return true
  false

`/** @namespace */`
app.message = {}
(->
  listener_store = {}

  app.message.send = (type, data) ->
    setTimeout (->
      if type of listener_store
        for listener in listener_store[type]
          listener(app.deep_copy(data))
      ), 0

  app.message.add_listener = (type, fn) ->
    setTimeout (->
      listener_store[type] or= []
      listener_store[type].push(fn)
      ), 0

  app.message.remove_listener = (type, fn) ->
    setTimeout (->
      for val, key in listener_store[type]
        if val is fn
          listener_store[type].splice(key, 1)
          return
      ), 0
)()

`/** @namespace */`
app.notice = {}
app.notice.push = (text) ->
  $("<div>")
    .append(
      $("<div>", {text}),
      $("<button>")
        .bind("click", ->
          $(this)
            .parent()
            .animate({opacity: 0}, "fast")
            .delay("fast")
            .slideUp("fast", -> $(this).remove())
          )
      )
    .hide()
    .appendTo("#app_notice_container")
    .fadeIn()

`/** @namespace */`
app.url = {}
app.url.fix = (url) ->
  url
    .replace(///
      ^(http://
        (?:
          [\w\.]+/test/read\.cgi/\w+/\d+
        | \w+\.machi\.to/bbs/read\.cgi/\w+/\d+
        | jbbs\.livedoor\.jp/bbs/read\.cgi/\w+/\d+/\d+
        | [\w\.]+/\w+(?:/\d+)?
        )
      ).*?$
      ///, "$1/")

app.url.guess_type = (url) ->
  url = app.url.fix(url)
  if ///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/\w+/\d+/\d+/$///.test(url)
    {type: "thread", bbs_type: "jbbs"}
  else if ///^http://jbbs\.livedoor\.jp/\w+/\d+/$///.test(url)
    {type: "board", bbs_type: "jbbs"}
  else if ///^http://\w+\.machi\.to/bbs/read\.cgi/\w+/\d+/$///.test(url)
    {type: "thread", bbs_type: "machi"}
  else if ///^http://\w+\.machi\.to/\w+/$///.test(url)
    {type: "board", bbs_type: "machi"}
  else if ///^http://[\w\.]+/test/read\.cgi/\w+/\d+/$///.test(url)
    {type: "thread", bbs_type: "2ch"}
  else if ///^http://[\w\.]+/\w+/$///.test(url)
    {type: "board", bbs_type: "2ch"}
  else
    return {type: "unknown", bbs_type: "unknown"};

app.url.thread_to_board = (thread_url) ->
  app.url.fix(thread_url)
    .replace(///^http://([\w\.]+)/(?:test|bbs)/read\.cgi/(\w+)/\d+/$///, "http://$1/$2/")
    .replace(///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/(\w+)/(\d+)/\d+/$///, "http://jbbs.livedoor.jp/$1/$2/")

`/** @namespace */`
app.config =
  set: (key, val) ->
    localStorage["config_#{key}"] = val
  get: (key) ->
    localStorage["config_#{key}"]
