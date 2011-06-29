app.board = {}

app.board._get_xhr_info = (board_url) ->
  tmp = ///^http://(\w+\.(\w+\.\w+))/(\w+)/(?:(\d+)/)?$///.exec(board_url)
  if not tmp
    return null
  switch tmp[2]
    when "machi.to"
      path: "http://#{tmp[1]}/bbs/offlaw.cgi/#{tmp[3]}/"
      charset: "Shift_JIS"
    when "livedoor.jp"
      path: "http://jbbs.livedoor.jp/#{tmp[3]}/#{tmp[4]}/subject.txt"
      charset: "EUC-JP"
    else
      path: "http://#{tmp[1]}/#{tmp[3]}/subject.txt"
      charset: "Shift_JIS"

app.board.get = (url, callback) ->
  tmp = app.board._get_xhr_info(url)
  if not tmp
    callback(status: "error")
    return
  xhr_path = tmp.path
  xhr_charset = tmp.charset

  app.cache.get(xhr_path)
    .pipe (cache) ->
      $.Deferred (deferred) ->
        if Date.now() - cache.data.last_updated < 1000 * 3
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
            if xhr.status is 200 and
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
              "If-Modified-Since"
              new Date(cache.data.last_modified).toUTCString()
            )

          if "etag" of cache.data
            xhr.setRequestHeader("If-None-Match", cache.data.etag)
        xhr.send(null)

    #パース部
    .pipe((fn = (cache, xhr) ->
      $.Deferred (deferred) ->
        if xhr?.status is 200
          board = app.board.parse(url, xhr.responseText)
        else if cache?.status is "success"
          board = app.board.parse(url, cache.data.data)

        if board
          if xhr?.status is 200 or xhr?.status is 304 or (not xhr and cache?.status is "success")
            deferred.resolve(cache, xhr, board)
          else
            deferred.reject(cache, xhr, board)
        else
          deferred.reject(cache, xhr)
    ), fn)

    #コールバック
    .done (cache, xhr, board) ->
      callback(status: "success", data: board)

    .fail (cache, xhr, board) ->
      if board
        callback(status: "error", data: board)
      else
        callback(status: "error")

    #キャシュ更新部
    .done (cache, xhr, board) ->
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

        if etag = xhr.getResponseHeader("ETag")
          cache.etag = etag

        app.cache.set(cache)

        for thread in board
          app.bookmark.update_res_count(thread.url, thread.res_count)
        null

      else if cache?.status is "success" and xhr?.status is 304
        cache.data.last_updated = Date.now()
        app.cache.set(cache.data)

    #dat落ちスキャン
    .done (cache, xhr, board) ->
      if board
        dict = {}
        for bookmark in app.bookmark.get_by_board(url)
          if bookmark.type is "thread"
            dict[bookmark.url] = true

        for thread in board
          if thread.url of dict
            delete dict[thread.url]

        for thread_url of dict
          app.message.send("detected_removed_dat", url: thread_url)
        null

app.board.parse = (url, text) ->
  tmp = /^http:\/\/(\w+\.(\w+\.\w+))\/(\w+)\/(\w+)?/.exec(url)
  switch tmp[2]
    when "machi.to"
      bbs_type = "machi"
      reg = /^\d+<>(\d+)<>(.+)\((\d+)\)$/gm
      base_url = "http://#{tmp[1]}/bbs/read.cgi/#{tmp[3]}/"
    when "livedoor.jp"
      bbs_type = "jbbs"
      reg = /^(\d+)\.cgi,(.+)\((\d+)\)$/gm
      base_url = "http://jbbs.livedoor.jp/bbs/read.cgi/#{tmp[3]}/#{tmp[4]}/"
    else
      bbs_type = "2ch"
      reg = /^(\d+)\.dat<>(.+) \((\d+)\)$/gm
      base_url = "http://#{tmp[1]}/test/read.cgi/#{tmp[3]}/"

  board = []
  while (reg_res = reg.exec(text))
    board.push(
      url: base_url + reg_res[1] + "/"
      title: reg_res[2]
      res_count: +reg_res[3]
      created_at: +reg_res[1] * 1000
    )

  if bbs_type is "jbbs"
    board.splice(-1, 1)

  if board.length > 0 then board else null
