`/** @namespace */`
app.thread = {}

app.thread._get_xhr_info = (thread_url) ->
  tmp = ///^http://(\w+\.(\w+\.\w+))/(?:test|bbs)/read\.cgi/
    (\w+)/(\d+)/(?:(\d+)/)?$///.exec(thread_url);
  if not tmp
    return null

  switch tmp[2]
    when "machi.to"
      path: "http://#{tmp[1]}/bbs/offlaw.cgi/#{tmp[3]}/#{tmp[4]}/",
      charset: "Shift_JIS"
    when "livedoor.jp"
      path: "http://jbbs.livedoor.jp/" +
          "bbs/rawmode.cgi/#{tmp[3]}/#{tmp[4]}/#{tmp[5]}/",
      charset: "EUC-JP"
    else
      path: "http://#{tmp[1]}/#{tmp[3]}/dat/#{tmp[4]}.dat",
      charset: "Shift_JIS"

app.thread.get = (url, callback) ->
  tmp = app.thread._get_xhr_info(url)
  if not tmp
    callback(status: "error")
    return
  xhr_path = tmp.path
  xhr_charset = tmp.charset

  app.cache.get xhr_path, (cache) ->
    if (cache.status is "success" and
        Date.now() - cache.data.last_updated < 1000 * 60)
      app.log("debug", "app.thread.get:
 期限内のキャッシュが見つかりました。キャッシュを返します。")
      callback
        status: "success"
        data: app.thread.parse(url, cache.data.data)
    else
      app.log("debug", "app.thread.get:
 期限内のキャッシュが見つかりませんでした。datの取得を試みます。")
      xhr = new XMLHttpRequest()
      xhr_timer = setTimeout((-> xhr.abort()), 1000 * 30)
      xhr.onreadystatechange = ->
        if xhr.readyState is 4
          clearTimeout(xhr_timer)

          if xhr.status is 200 and (thread = app.thread.parse(url, xhr.responseText))
            app.log("debug", "app.thread.get:
 datの取得に成功しました")
            callback(status: "success", data: thread)

            last_modified = new Date(xhr.getResponseHeader("Last-Modified") or "dummy").getTime()
            unless isNaN(last_modified)
              app.cache.set
                url: xhr_path
                data: xhr.responseText
                last_updated: Date.now()
                last_modified: last_modified
          else if cache.status is "success"
            if xhr.status is 304
              app.log("debug", "app.thread.get:
 datの取得に成功しました（更新無し）")
              callback
                status: "success"
                data: app.thread.parse(url, cache.data.data)
              cache.data.last_updated = Date.now()
              app.cache.set(cache.data)
            else
              app.log("debug", "app.thread.get:
 datの取得に失敗しました。キャッシュを返します。")
              callback
                status: "error"
                data: app.thread.parse(url, cache.data.data)
          else
            app.log("debug", "app.thread.get:
 datの取得に失敗しました。")
            callback(status: "error")
      xhr.overrideMimeType("text/plain; charset=" + xhr_charset)
      xhr.open("GET", xhr_path + "?_=" + Date.now().toString(10))
      if cache.status is "success"
        xhr.setRequestHeader(
          "If-Modified-Since",
          new Date(cache.data.last_modified).toUTCString()
        )
      xhr.send(null)

app.thread.parse = (url, text) ->
  tmp = /^http:\/\/\w+\.(\w+\.\w+)\//.exec(url)
  if not tmp
    return null
  if tmp[1] is "machi.to"
    return app.thread._parse_machi(text)
  else if tmp[1] is "livedoor.jp"
    return app.thread._parse_jbbs(text)
  else
    return app.thread._parse_ch(text)

app.thread._parse_ch = (text) ->
  # name, mail, other, message, thread_title
  reg = /^(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm

  thread = {res: []}
  first_flg = true
  while (reg_res = reg.exec(text))
    if first_flg
      thread.title = reg_res[5]
      first_flg = false
    thread.res.push
      name: reg_res[1]
      mail: reg_res[2]
      message: reg_res[4]
      other: reg_res[3]
  if thread.res.length > 0 then thread else null

app.thread._parse_machi = (text) ->
  # res_num, name, mail, other, message, thread_title
  reg = /^(\d+)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm

  thread = {res: []}
  res_count = 0
  while (reg_res = reg.exec(text))
    while (++res_count isnt +reg_res[1])
      thread.res.push
        name: "あぼーん"
        mail: "あぼーん"
        message: "あぼーん"
        other: "あぼーん"

    if res_count is 1
      thread.title = reg_res[6]
    thread.res.push
      name: reg_res[2]
      mail: reg_res[3]
      message: reg_res[5]
      other: reg_res[4]

  if thread.res.length > 0 then thread else null

app.thread._parse_jbbs = (text) ->
  # res_num, name, mail, date, message, thread_title, id
  reg = /^(\d+)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm

  thread = {res: []}
  res_count = 0
  while (reg_res = reg.exec(text))
    while (++res_count isnt +reg_res[1])
      thread.res.push
        name: "あぼーん"
        mail: "あぼーん"
        message: "あぼーん"
        other: "あぼーん"

    if res_count is 1
      thread.title = reg_res[6]
    thread.res.push
      name: reg_res[2]
      mail: reg_res[3]
      message: reg_res[5]
      other: reg_res[4] + " ID:" + reg_res[7]
  if thread.res.length > 0 then thread else null
