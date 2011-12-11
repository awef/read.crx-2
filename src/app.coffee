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

  return

app.log = (level, data...) ->
  if level in ["log", "debug", "info", "warn", "error"]
    console[level].apply(console, data)
  else
    app.log("error", "app.log: 引数levelが不正な値です", arguments)
  return

app.deep_copy = do ->
  fn = (original) ->
    if typeof(original) isnt "object" or original is null
      return original
    res = if Array.isArray(original) then [] else {}
    for key of original
      res[key] = fn(original[key])
    res

app.defer = (fn) ->
  setTimeout(fn, 0)
  return

app.assert_arg = (name, rule, arg) ->
  for val, key in rule
    unless typeof arg[key] is val
      app.log("error", "#{name}: 不正な引数", app.deep_copy(arg))
      return true
  false

app.message = do ->
  listener_store = {}

  fire = (type, message) ->
    app.defer ->
      if type of listener_store
        for listener in listener_store[type]
          listener?(app.deep_copy(message))
    return

  window.addEventListener "message", (e) ->
    return if e.origin isnt location.origin

    data = JSON.parse(e.data)

    return if data.type isnt "app.message"

    #parentから伝わってきた場合はiframeにも伝える
    if e.source is parent
      for iframe in document.getElementsByTagName("iframe")
        iframe.contentWindow.postMessage(e.data, location.origin)
    #iframeから伝わってきた場合は、parentと他のiframeにも伝える
    else
      if parent isnt window
        parent.postMessage(e.data, location.origin)
      for iframe in document.getElementsByTagName("iframe")
        continue if iframe.contentWindow is e.source
        iframe.contentWindow.postMessage(e.data, location.origin)

    fire(data.message_type, data.message)
    return

  {
    send: (type, message) ->
      json = JSON.stringify
        type: "app.message"
        message_type: type
        message: message
      if parent isnt window
        parent.postMessage(json, location.origin)
      for iframe in document.getElementsByTagName("iframe")
        iframe.contentWindow.postMessage(json, location.origin)

      fire(type, message)
      return

    add_listener: (type, listener) ->
      listener_store[type] or= []
      listener_store[type].push(listener)
      return

    remove_listener: (type, listener) ->
      for val, key in listener_store[type]
        if val is listener
          listener_store[type].splice(key, 1)
          break
      return
  }

app.config =
  set: (key, val) ->
    localStorage["config_#{key}"] = val
    return
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
    return

app.escape_html = (str) ->
  str
    .replace(/\&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;")

app.safe_href = (url) ->
  if /// ^https?:// ///.test(url) then url else "/view/empty.html"

# app.manifest
do ->
  if location.origin is chrome.extension.getURL("")[...-1]
    xhr = new XMLHttpRequest()
    xhr.open("GET", "/manifest.json", false)
    xhr.send(null)
    app.manifest = JSON.parse(xhr.responseText)

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
  return
