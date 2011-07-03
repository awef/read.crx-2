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

app.config =
  set: (key, val) ->
    localStorage["config_#{key}"] = val
  get: (key) ->
    localStorage["config_#{key}"]
  del: (key) ->
    delete localStorage["config_#{key}"]

app.safe_href = (url) ->
  if /// ^https?:// ///.test(url) then url else "http://google.co.jp/"
