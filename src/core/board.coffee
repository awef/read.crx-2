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
    callback(status: "error", message: "未対応のURLです")
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
          if cache.data.last_modified?
            xhr.setRequestHeader(
              "If-Modified-Since"
              new Date(cache.data.last_modified).toUTCString()
            )

          if cache.data.etag?
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
      message = "板の読み込みに失敗しました。"

      #2chでrejectされている場合は移転を疑う
      if app.url.tsld(url) is "2ch.net" and xhr
        app.util.ch_server_move_detect(url)
          #移転検出時
          .done (new_board_url) ->
            message += """
            サーバーが移転している可能性が有ります
            (<a href="#{app.escape_html(app.safe_href(new_board_url))}"
            class="open_in_rcrx">#{app.escape_html(new_board_url)}
            </a>)
            """
          .always ->
            if cache?.status is "success" and board
              message += "キャシュに残っていたデータを表示します。"

            if board
              callback({status: "error", data: board, message})
            else
              callback({status: "error", message})
      else
        if cache?.status is "success" and board
          message += "キャシュに残っていたデータを表示します。"

        if board
          callback({status: "error", data: board, message})
        else
          callback({status: "error", message})

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
          if dict[thread.url]?
            delete dict[thread.url]
            app.bookmark.update_expired(thread.url, false)

        for thread_url of dict
          app.bookmark.update_expired(thread_url, true)
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
      title: app.util.decode_char_reference(reg_res[2])
      res_count: +reg_res[3]
      created_at: +reg_res[1] * 1000
    )

  if bbs_type is "jbbs"
    board.splice(-1, 1)

  if board.length > 0 then board else null

app.board.get_cached_res_count = (thread_url, callback) ->
  board_url = app.url.thread_to_board(thread_url)
  xhr_path = app.board._get_xhr_info(board_url)?.path
  if not xhr_path
    app.log("error", "app.board.get_cached_res_count: 未対応のURLです#{thread_url}")
    callback(null)
    return

  app.cache.get(xhr_path)
    .pipe (cache) ->
      $.Deferred (deferred) ->
        last_modified = cache.data.last_modified
        board = app.board.parse(board_url, cache.data.data)
        for thread in board
          if thread.url is thread_url
            deferred.resolve(thread, last_modified)
            return
        deferred.reject()
    .done (thread, last_modified) ->
      callback({res_count: thread.res_count, modified: last_modified})
    .fail ->
      callback(null)
  return
