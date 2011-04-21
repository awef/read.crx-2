app.board = {}

app.board._get_xhr_info = (board_url) ->
  tmp = ///^http://(\w+\.(\w+\.\w+))/(\w+)/(?:(\d+)/)?$///.exec(board_url)
  if not tmp
    return null
  switch tmp[2]
    when "machi.to"
      {
        path: "http://#{tmp[1]}/bbs/offlaw.cgi/#{tmp[3]}/"
        charset: "Shift_JIS"
      }
    when "livedoor.jp"
      {
        path: "http://jbbs.livedoor.jp/#{tmp[3]}/#{tmp[4]}/subject.txt"
        charset: "EUC-JP"
      }
    else
      {
        path: "http://#{tmp[1]}/#{tmp[3]}/subject.txt"
        charset: "Shift_JIS"
      }

app.board.get = (url, callback) ->
  tmp = app.board._get_xhr_info(url)
  if not tmp
    callback(status: "error")
    return
  xhr_path = tmp.path
  xhr_charset = tmp.charset

  app.cache.get xhr_path, (cache) ->
    if cache.status is "success" and Date.now() - cache.data.last_updated < 1000 * 60
      callback(
        status: "success"
        data: app.board.parse(url, cache.data.data)
      )
    else
      xhr = new XMLHttpRequest()
      xhr_timer = setTimeout((-> xhr.abort()), 1000 * 30)
      xhr.onreadystatechange = ->
        if xhr.readyState is 4
          clearTimeout(xhr_timer)

          if (
            xhr.status is 200 and
            (board = app.board.parse(url, xhr.responseText))
          )
            callback(success: "success", data: board)

            last_modified = new Date(xhr.getResponseHeader("Last-Modified") or "dummy").getTime()
            unless isNaN(last_modified)
              app.cache.set(
                url: xhr_path
                data: xhr.responseText
                last_updated: Date.now()
                last_modified: last_modified
              )
          else if cache.status is "success"
            if xhr.status is 304
              callback(
                status: "success"
                data: app.board.parse(url, cache.data.data)
              )
              cache.data.last_updated = Date.now()
              app.cache.set(cache.data)
            else
              callback(
                status: "error"
                data: app.board.parse(url, cache.data.data)
              )
          else
            callback(status: "error")
      xhr.overrideMimeType("text/plain; charset=" + xhr_charset)
      xhr.open("GET", xhr_path + "?_=" + Date.now().toString(10))
      if cache.status is "success"
        xhr.setRequestHeader(
          "If-Modified-Since"
          new Date(cache.data.last_modified).toUTCString()
        )
      xhr.send(null)

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
