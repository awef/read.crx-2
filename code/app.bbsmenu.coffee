`/** @namespace */`
app.bbsmenu = {}

app.bbsmenu.get = (callback) ->
  url = "http://menu.2ch.net/bbsmenu.html"

  app.cache.get url, (cache) ->
    if cache.status is "success" and
        Date.now() - cache.data.last_updated < 1000 * 60 * 60 * 12
      menu = app.bbsmenu.parse(cache.data.data)
      app.log("debug", "app.bbsmenu.get:
 期限内のキャッシュが見つかりました。キャッシュを返します。")
      callback(status: "success", data: menu)
    else
      app.log("debug", "app.bbsmenu.get:
 期限内のキャッシュが見つかりませんでした。bbsmenu.htmlの取得を試みます。")
      xhr = new XMLHttpRequest()
      xhr_timer = setTimeout((-> xhr.abort()), 1000 * 30)
      xhr.onreadystatechange = ->
        if xhr.readyState is 4
          clearTimeout(xhr_timer)
          if xhr.status is 200 and
              (menu = app.bbsmenu.parse(this.responseText))
            app.log("debug", "app.bbsmenu.get:
 bbsmenu.htmlの取得に成功しました")
            callback(status: "success", data: menu)
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
          else if cache.status is "success"
            if xhr.status is 304
              app.log("debug", "app.bbsmenu.get:
 bbsmenu.htmlの取得に成功しました（更新無し）")
              callback(
                status: "success"
                data: app.bbsmenu.parse(cache.data.data)
              )
              cache.data.last_updated = Date.now()
              app.cache.set(cache.data)
            else
              app.log("debug", "app.bbsmenu.get:
 bbsmenu.htmlの取得に失敗しました。キャッシュを返します。")
              callback(
                status: "error"
                data: app.bbsmenu.parse(cache.data.data)
              )
          else
            app.log("debug", "app.bbsmenu.get:
 bbsmenu.htmlの取得に失敗しました。")
            callback(status: "error")
      xhr.overrideMimeType("text/plain; charset=Shift_JIS")
      xhr.open("GET", url + "?_=" + Date.now().toString(10))
      if cache.status is "success"
        xhr.setRequestHeader(
          "If-Modified-Since",
          new Date(cache.data.last_modified).toUTCString()
        )
      xhr.send(null)

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
      category.board.push({
        url: reg_board_res[1],
        title: reg_board_res[2]
      })

    if category.board.length > 0
      menu.push(category)

  if menu.length > 0 then menu else null
