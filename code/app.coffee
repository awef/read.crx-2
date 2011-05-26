`/** @namespace */`
app = {}

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
  app.view.init()
  app.view.load_sidemenu()

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

app.defer = (fn) ->
  setTimeout(fn, 0)

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
    app.defer ->
      if type of listener_store
        for listener in listener_store[type]
          listener(app.deep_copy(data))

  app.message.add_listener = (type, fn) ->
    listener_store[type] or= []
    listener_store[type].push(fn)

  app.message.remove_listener = (type, fn) ->
    for val, key in listener_store[type]
      if val is fn
        listener_store[type].splice(key, 1)
        return
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
app.config =
  set: (key, val) ->
    localStorage["config_#{key}"] = val
  get: (key) ->
    localStorage["config_#{key}"]
