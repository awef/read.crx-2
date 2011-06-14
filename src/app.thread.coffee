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

  app.cache.get(xhr_path)
    #キャッシュ取得部
    .pipe (cache) ->
      $.Deferred (deferred) ->
        if Date.now() - cache.data.last_updated < 1000 * 60
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
        xhr.overrideMimeType("text/plain; charset=" + xhr_charset)
        xhr.open("GET", xhr_path + "?_=" + Date.now().toString(10))
        if cache.status is "success"
          if "last_modified" of cache.data
            xhr.setRequestHeader(
              "If-Modified-Since",
              new Date(cache.data.last_modified).toUTCString()
            )

          if "etag" of cache.data
            xhr.setRequestHeader("If-None-Match", cache.data.etag)
        xhr.send(null)

    #パース部
    .pipe((fn = (cache, xhr) ->
      $.Deferred (deferred) ->
        guess_res = app.url.guess_type(url)

        if xhr?.status is 200
          thread = app.thread.parse(url, xhr.responseText)
        #2ch系BBSのdat落ち
        else if guess_res.bbs_type is "2ch" and xhr?.status is 203
          if cache?.status is "success"
            thread = app.thread.parse(url, cache.data.data)
          else
            thread = app.thread.parse(url, xhr.responseText)
        else if cache?.status is "success"
          thread = app.thread.parse(url, cache.data.data)

        #パース成功
        if thread
          #通信成功
          if xhr?.status is 200 or
              #通信成功（更新なし）
              xhr?.status is 304 or
              #キャッシュが期限内だった場合
              (not xhr and cache?.status is "success")
            deferred.resolve(cache, xhr, thread)
          #2ch系BBSのdat落ち
          else if guess_res.bbs_type is "2ch" and xhr?.status is 203
            deferred.reject(cache, xhr, thread)
            app.message.send("detected_removed_dat", url: url)
          else
            deferred.reject(cache, xhr, thread)
        #パース失敗
        else
          deferred.reject(cache, xhr)
    ), fn)

    #コールバック
    .done (cache, xhr, thread) ->
      callback(status: "success", data: thread)

    .fail (cache, xhr, thread) ->
      message = ""
      if xhr?.status is 203
        message = "dat落ちしたスレッドです。"
      else
        message = "スレッドの読み込みに失敗しました。"
      if cache?.status is "success" and thread
        message += "キャッシュに残っていたデータを表示します。"

      if thread
        callback({status: "error", data: thread, message})
      else
        callback({status: "error", message})

    #キャッシュ更新部
    .done (cache, xhr, thread) ->
      #通信に成功した場合
      if xhr?.status is 200
        cache =
          url: xhr_path
          data: xhr.responseText
          last_updated: Date.now()

        last_modified = new Date(
          xhr.getResponseHeader("Last-Modified") or "dummy"
        ).getTime()

        if not isNaN(last_modified)
          cache.last_modified = last_modified

        etag = xhr.getResponseHeader("ETag")
        if etag
          cache.etag = etag

        app.cache.set(cache)
        app.bookmark.update_res_count(url, thread.res.length)

      #304だった場合はアップデート時刻のみ更新
      else if cache?.status is "success" and xhr?.status is 304
        cache.data.last_updated = Date.now()
        app.cache.set(cache.data)

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
