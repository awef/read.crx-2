app.bbsmenu = {}

app.bbsmenu._callback = []

app.bbsmenu._respond = (arg) ->
  for callback in app.bbsmenu._callback
    #コールバック内でapp.bbsmenu.getされる場合に備えて処理を飛ばす
    ((callback) ->
      app.defer ->
        callback(app.deep_copy(arg))
    )(callback)
  app.bbsmenu._callback = []

app.bbsmenu.get = (callback, force_reload) ->
  app.bbsmenu._callback.push(callback)

  return if app.bbsmenu._callback.length isnt 1

  url = "http://menu.2ch.net/bbsmenu.html"

  app.cache.get(url)
    #キャッシュ取得部
    .pipe (cache) ->
      $.Deferred (deferred) ->
        if force_reload
          deferred.reject(cache)
        else if Date.now() - cache.data.last_updated < 1000 * 60 * 60 * 12
          deferred.resolve(cache)
        else
          deferred.reject(cache)

    #通信部
    .pipe null, (cache) ->
      $.Deferred (deferred) ->
        xhr = new XMLHttpRequest()
        xhr_timer = setTimeout((-> xhr.abort()), 1000 * 30)
        xhr.onreadystatechange = ->
          if xhr.readyState is 4
            clearTimeout(xhr_timer)
            if xhr.status is 200
              deferred.resolve(cache, xhr)
            else if cache.status is "success" and xhr.status is 304
              deferred.resolve(cache, xhr)
            else
              deferred.reject(cache, xhr)
        xhr.overrideMimeType("text/plain; charset=Shift_JIS")
        xhr.open("GET", url + "?_=" + Date.now().toString(10))
        if cache.status is "success"
          xhr.setRequestHeader(
            "If-Modified-Since",
            new Date(cache.data.last_modified).toUTCString()
          )
        xhr.send(null)

    #パース部
    .pipe((fn = (cache, xhr) ->
      $.Deferred (deferred) ->
        if xhr?.status is 200
          menu = app.bbsmenu.parse(xhr.responseText)
        else if cache?.status is "success"
          menu = app.bbsmenu.parse(cache.data.data)

        if menu
          if xhr?.status is 200 or xhr?.status is 304 or (not xhr and cache?.status is "success")
            deferred.resolve(cache, xhr, menu)
          else
            deferred.reject(cache, xhr, menu)
        else
          deferred.reject(cache, xhr)
    ), fn)

    #コールバック
    .done (cache, xhr, menu) ->
      app.bbsmenu._respond(status: "success", data: menu)

    .fail (cache, xhr, menu) ->
      message = "板一覧の取得に失敗しました。"
      if menu
        message += "キャッシュに残っていたデータを表示します。"
        app.bbsmenu._respond({status: "error", data: menu, message})
      else
        app.bbsmenu._respond({status: "error", message})

    #キャッシュ更新部
    .done (cache, xhr, menu) ->
      if xhr?.status is 200
        last_modified = new Date(
          xhr.getResponseHeader("Last-Modified") or "dummy"
        ).getTime()

        unless isNaN(last_modified)
          app.cache.set({
            url
            data: xhr.responseText
            last_updated: Date.now()
            last_modified: last_modified
          })
      else if cache?.status is "success" and xhr?.status is 304
        cache.data.last_updated = Date.now()
        app.cache.set(cache.data)

app.bbsmenu.parse = (html) ->
  reg_category = ///<b>(.+?)</b>(?:.*\n<a\s.*?>.+?</a>)+///gi
  reg_board = ///<a\shref=(http://(?!info\.2ch\.net/)
    \w+\.(?:2ch\.net|machi\.to)/\w+/)(?:\s.*?)?>(.+?)</a>///gi

  menu = []

  while reg_category_res = reg_category.exec(html)
    category =
      title: reg_category_res[1]
      board: []

    while reg_board_res = reg_board.exec(reg_category_res[0])
      category.board.push
        url: reg_board_res[1]
        title: reg_board_res[2]

    if category.board.length > 0
      menu.push(category)

  if menu.length > 0 then menu else null
