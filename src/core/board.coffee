app.module "board", ["jquery", "cache"], ($, Cache, callback) ->
  class Board
    constructor: (@url) ->
      @thread = null
      @message = null
      return

    get: ->
      res_deferred = $.Deferred()

      tmp = Board._get_xhr_info(@url)
      unless tmp
        return res_deferred.reject().promise()
      xhr_path = tmp.path
      xhr_charset = tmp.charset

      #キャッシュ取得
      cache = new Cache(xhr_path)
      cache_get_promise = cache.get()
      cache_get_promise.pipe ->
        $.Deferred (d) ->
          if Date.now() - cache.last_updated < 1000 * 3
            d.resolve()
          else
            d.reject()
          return
      #通信
      .pipe null, =>
        $.Deferred (d) ->
          ajax_data =
            url: xhr_path
            cache: false
            dataType: "text"
            headers: {}
            mimeType: "text/plain; charset=" + xhr_charset
            timeout: 1000 * 30
            complete: ($xhr) ->
              if $xhr.status is 200
                d.resolve($xhr)
              else if cache_get_promise.isResolved() and $xhr.status is 304
                d.resolve($xhr)
              else
                d.reject($xhr)
              return

          if cache_get_promise.isResolved
            if cache.last_modified?
              ajax_data.headers["If-Modified-Since"] =
                new Date(cache.last_modified).toUTCString()

            if cache.etag?
              ajax_data.headers["If-None-Match"] = cache.etag

          $.ajax(ajax_data)
          return
      #パース
      .pipe((fn = ($xhr) =>
        $.Deferred (d) =>
          if $xhr?.status is 200
            thread_list = Board.parse(@url, $xhr.responseText)
          else if cache_get_promise.isResolved()
            thread_list = Board.parse(@url, cache.data)

          if thread_list?
            if $xhr?.status is 200 or $xhr?.status is 304 or (not $xhr? and cache_get_promise.isResolved())
              d.resolve($xhr, thread_list)
            else
              d.reject($xhr, thread_list)
          else
            d.reject($xhr)
          return
      ), fn)
      #コールバック
      .done ($xhr, thread_list) =>
        @thread = thread_list
        res_deferred.resolve()
        return

      .fail ($xhr, thread_list) =>
        @message = "板の読み込みに失敗しました。"

        #2chでrejectされている場合は移転を疑う
        if app.url.tsld(@url) is "2ch.net" and $xhr?
          app.util.ch_server_move_detect(@url)
            #移転検出時
            .done (new_board_url) =>
              @message += """
              サーバーが移転している可能性が有ります
              (<a href="#{app.escape_html(app.safe_href(new_board_url))}"
              class="open_in_rcrx">#{app.escape_html(new_board_url)}
              </a>)
              """
            .always =>
              if cache_get_promise.isResolved() and thread_list?
                @message += "キャシュに残っていたデータを表示します。"

              if thread_list
                @thread = thread_list
        else
          if cache_get_promise.isResolved() and thread_list?
            @message += "キャシュに残っていたデータを表示します。"

          if thread_list?
            @thread = thread_list
        res_deferred.reject()
        return
      #キャシュ更新部
      .done ($xhr, thread_list) ->
        if $xhr?.status is 200
          cache.data = $xhr.responseText
          cache.last_updated = Date.now()

          last_modified = new Date(
            $xhr.getResponseHeader("Last-Modified") or "dummy"
          ).getTime()

          if not isNaN(last_modified)
            cache.last_modified = last_modified

          if etag = $xhr.getResponseHeader("ETag")
            cache.etag = etag

          cache.put()

          for thread in thread_list
            app.bookmark.update_res_count(thread.url, thread.res_count)
          null

        else if cache_get_promise.isResolved() and $xhr?.status is 304
          cache.last_updated = Date.now()
          cache.put()
        return
      #dat落ちスキャン
      .done ($xhr, thread_list) =>
        if thread_list
          dict = {}
          for bookmark in app.bookmark.get_by_board(@url) when bookmark.type is "thread"
            dict[bookmark.url] = true

          for thread in thread_list when dict[thread.url]?
            delete dict[thread.url]
            app.bookmark.update_expired(thread.url, false)

          for thread_url of dict
            app.bookmark.update_expired(thread_url, true)
        return
      res_deferred.promise()

    @_get_xhr_info: (board_url) ->
      tmp = ///^http://(\w+\.(\w+\.\w+))/(\w+)/(?:(\d+)/)?$///.exec(board_url)
      unless tmp
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

    @parse: (url, text) ->
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

    @get_cached_res_count: (thread_url) ->
      board_url = app.url.thread_to_board(thread_url)
      xhr_path = Board._get_xhr_info(board_url)?.path

      unless xhr_path?
        return $.Deferred().reject().promise()

      cache = new Cache(xhr_path)
      cache.get().pipe =>
        $.Deferred (d) =>
          last_modified = cache.last_modified
          for thread in Board.parse(board_url, cache.data)
            if thread.url is thread_url
              d.resolve
                res_count: thread.res_count
                modified: last_modified
              return
          d.reject()
          return
      .promise()

  callback(Board)
  return

app.board =
  get: (url, callback) ->
    app.module null, ["board"], (Board) ->
      board = new Board(url)
      board.get()
        .done ->
          callback(status: "success", data: board.thread)
          return
        .fail ->
          tmp = {status: "error"}
          if board.message?
            tmp.message = board.message
          if board.thread?
            tmp.data = board.thread
          callback(tmp)
          return
      return
    return

  get_cached_res_count: (thread_url, callback) ->
    app.module null, ["board"], (Board) ->
      Board.get_cached_res_count(thread_url)
        .done (res) ->
          callback(res)
          return
        .fail ->
          callback(null)
          return
      return
    return
