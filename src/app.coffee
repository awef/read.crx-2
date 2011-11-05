app = {}

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
  if level in ["log", "debug", "info", "warn", "error"]
    console[level].apply(console, Array::slice.call(arguments, 1))
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
      if listener_store[type]?
        listener_store[type].forEach (listener) ->
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

app.config =
  set: (key, val) ->
    localStorage["config_#{key}"] = val
  get: (key) ->
    def =
      thumbnail_supported: "on"
      always_new_tab: "on"
      layout: "pane-3"
      default_name: ""
      default_mail: ""
      popup_trigger: "click"
    if localStorage["config_#{key}"]?
      localStorage["config_#{key}"]
    else if def[key]?
      def[key]
    else
      undefined
  del: (key) ->
    delete localStorage["config_#{key}"]

app.safe_href = (url) ->
  if /// ^https?:// ///.test(url) then url else "/view/empty.html"

# app.manifest
(->
  if location.origin is chrome.extension.getURL("").slice(0, -1)
    xhr = new XMLHttpRequest()
    xhr.open("GET", "/manifest.json", false)
    xhr.send(null)
    app.manifest = JSON.parse(xhr.responseText)
)()

app.boot = (path, fn) ->
  #Chromeがiframeのsrcと無関係な内容を読み込むバグへの対応
  if frameElement and frameElement.src isnt location.href
    location.href = frameElement.src
    return

  if location.pathname is path
    html_version = document.documentElement.getAttribute("data-app-version")
    if app.manifest.version isnt html_version
      location.reload(true)
    else
      $(fn)

