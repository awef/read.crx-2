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

  app.view.tab_state.restore()
  window.addEventListener "unload", ->
    app.view.tab_state.store()

  chrome.extension.onRequest.addListener (request) ->
    if request.type is "open"
      app.message.send("open", url: request.query)

app.critical_error = (message) ->
  webkitNotifications
    .createNotification(
      "",
      "深刻なエラーが発生したのでread.crxを終了します",
      "詳細 : " + message
    )
    .show()

  chrome.tabs.getCurrent (tab) ->
    chrome.tabs.remove(tab.id)

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

app.message = {}
(->
  listener_store = {}

  app.message.send = (type, data) ->
    app.defer ->
      if type of listener_store
        for listener in listener_store[type]
          listener(app.deep_copy(data))
        null

  app.message.add_listener = (type, fn) ->
    listener_store[type] or= []
    listener_store[type].push(fn)

  app.message.remove_listener = (type, fn) ->
    for val, key in listener_store[type]
      if val is fn
        listener_store[type].splice(key, 1)
        return
)()

app.config =
  set: (key, val) ->
    localStorage["config_#{key}"] = val
  get: (key) ->
    localStorage["config_#{key}"]
  del: (key) ->
    delete localStorage["config_#{key}"]
