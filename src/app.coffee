app = {}

app.critical_error = (message) ->
  webkitNotifications
    .createNotification(
      "",
      "深刻なエラーが発生したのでread.crxを終了します",
      "詳細 : " + message
    )
    .show()

  parent.chrome.tabs.getCurrent (tab) ->
    parent.chrome.tabs.remove(tab.id)
    return

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

###*
@class Callbacks
@namespace app
@constructor
@param {Object} [config]
  @param {Boolean} [config.persistent=false]
###
class app.Callbacks
  constructor: (config = {}) ->
    ###*
    @property _config
    @private
    @type Object
    ###
    @_config = config

    ###*
    @property _callbackStore
    @private
    @type Array | null
    ###
    @_callbackStore = []

    ###*
    @property _latestCallArg
    @private
    @type null | Array
    ###
    @_latestCallArg = null
    return

  ###*
  @method add
  @param {Function} callback
  ###
  add: (callback) ->
    if not @_config.persistent and @_latestCallArg?
      callback.apply(null, app.deep_copy(@_latestCallArg))
    else
      @_callbackStore.push(callback)
    return

  ###*
  @method remove
  @param {Function} callback
  ###
  remove: (callback) ->
    index = @_callbackStore.indexOf(callback)
    if index isnt -1
      @_callbackStore.splice(index, 1)
    else
      app.log("error",
        "app.Callbacks: 存在しないコールバックを削除しようとしました。")
    return

  ###*
  @method call
  @param [arguments]*
  ###
  call: ->
    arg = Array::slice.call(arguments)

    if not @_config.persistent and @_latestCallArg?
      app.log("error",
        "app.Callbacks: persistentでないCallbacksが複数回callされました。")
    else
      @_latestCallArg = app.deep_copy(arg)

      tmpCallbackStore = @_callbackStore.slice()

      for callback in tmpCallbackStore when callback in @_callbackStore
        callback.apply(null, app.deep_copy(arg))

      if not @_config.persistent
        @_callbackStore = null
    return

app.message = do ->
  listenerStore = {}

  fire = (type, message) ->
    message = app.deep_copy(message)
    app.defer ->
      listenerStore[type]?.call(message)
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
      if not listenerStore[type]?
        listenerStore[type] = new app.Callbacks(persistent: true)
      listenerStore[type].add(listener)
      return

    remove_listener: (type, listener) ->
      listenerStore[type]?.remove(listener)
      return
  }

###*
@namespace app
@class Config
@constructor
###
class app.Config
  constructor: ->
    ###*
    @property _cache
    @private
    @type Object | null
    ###
    @_cache = {}

    ###*
    @method ready
    @param {Function}
    ###
    ready = new app.Callbacks()
    @ready = ready.add.bind(ready)

    # localStorageからの移行処理
    do =>
      found = {}
      for index in [0...localStorage.length]
        key = localStorage.key(index)
        if /^config_/.test(key)
          val = localStorage.getItem(key)
          @_cache[key] = val
          found[key] = val

      chrome.storage.local.set(found)

      for key in Object.keys(found)
        localStorage.removeItem(key)
      return

    chrome.storage.local.get null, (res) =>
      if @_cache isnt null
        for key, val of res when /^config_/.test(key) and typeof val in ["string", "number"]
          @_cache[key] = val
        ready.call()
      return

    @_onChanged = ((change, area) =>
      if area is "local"
        for key, info of change when /^config_/.test(key)
          if typeof info.newValue is "string"
            @_cache[key] = info.newValue
            app.message.send("config_updated", {
              key: key.slice(7)
              val: info.newValue
            })
          else
            delete @_cache[key]
      return
    ).bind(@)

    chrome.storage.onChanged.addListener(@_onChanged)
    return

  ###*
  @property _default
  @static
  @private
  @type Object
  ###
  @_default:
    thumbnail_supported: "on"
    always_new_tab: "on"
    layout: "pane-3"
    default_name: ""
    default_mail: ""
    popup_trigger: "click"
    theme_id: "default"
    user_css: ""

  ###*
  @method get
  @param {String} key
  @return {String|undefined} val
  ###
  get: (key) ->
    if @_cache["config_#{key}"]?
      @_cache["config_#{key}"]
    else if Config._default[key]?
      Config._default[key]
    else
      undefined

  ###*
  @method set
  @param {String} key
  @param {String} val
  ###
  set: (key, val) ->
    if typeof key isnt "string" or not (typeof val in ["string", "number"])
      app.log("error", "app.Config::setに不適切な値が渡されました", arguments)
      return

    tmp = {}
    tmp["config_#{key}"] = val
    chrome.storage.local.set(tmp)
    return

  ###*
  @method del
  @param {String} key
  ###
  del: (key) ->
    if typeof key isnt "string"
      app.log("error", "app.Config::delにstring以外の値が渡されました", arguments)
      return

    chrome.storage.local.remove("config_#{key}")
    return

  ###*
  @method destroy
  ###
  destroy: ->
    @_cache = null
    chrome.storage.onChanged.removeListener(@_onChanged)
    return

if not frameElement?
  app.config = new app.Config()

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
  if /^chrome-extension:\/\//.test(location.origin)
    xhr = new XMLHttpRequest()
    xhr.open("GET", "/manifest.json", false)
    xhr.send()
    app.manifest = JSON.parse(xhr.responseText)
  return

# app.module
do ->
  pending_modules = []
  ready_modules = {}

  fire_definition = (module_id, dependencies, definition) ->
    dep_modules = []
    for dep_module_id in dependencies
      dep_modules.push(ready_modules[dep_module_id].module)

    if module_id isnt null
      callback = add_ready_module.bind({module_id, dependencies})
      app.defer ->
        definition(dep_modules..., callback)
    else
      app.defer ->
        definition(dep_modules...)
        return

  add_ready_module = (module) ->
    ready_modules[@module_id] = {@dependencies, module}

    #このモジュールが初期化された事で依存関係が満たされたモジュールを初期化
    pending_modules = pending_modules.filter (val) =>
      if @module_id in val.dependencies
        unless val.dependencies.some((a) -> not ready_modules[a]?)
          fire_definition(val.module_id, val.dependencies, val.definition)
          return false
      true

  app.module = (module_id = null, dependencies = [], definition) ->
    #依存関係が満たされていないモジュールは、しまっておく
    if dependencies.some((a) -> not ready_modules[a]?)
      pending_modules.push({module_id, dependencies, definition})
    #依存関係が満たされている場合、即座にモジュール初期化を開始する
    else
      fire_definition(module_id, dependencies, definition)

  if window.jQuery?
    app.module "jquery", [], (callback) ->
      callback(window.jQuery)

app.boot = (path, [requirements]..., fn) ->
  #Chromeがiframeのsrcと無関係な内容を読み込むバグへの対応
  if frameElement and frameElement.src isnt location.href
    location.href = frameElement.src
    return

  if location.pathname is path
    html_version = document.documentElement.getAttribute("data-app-version")
    if app.manifest.version isnt html_version
      location.reload(true)
    else
      $ ->
        app.config.ready ->
          if requirements?
            app.module(null, requirements, fn)
          else
            fn()
          return
        return
  return

app.clipboardWrite = (str) ->
  input = document.createElement("input")
  input.value = str
  document.body.appendChild(input)
  input.select()
  document.execCommand("copy")
  document.body.removeChild(input)
  return
