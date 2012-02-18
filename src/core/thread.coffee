app.module "thread", ["jquery", "cache"], ($, Cache, callback) ->
  get_xhr_info = (thread_url) ->
    tmp = ///^http://(\w+\.(\w+\.\w+))/(?:test|bbs)/read\.cgi/
      (\w+)/(\d+)/(?:(\d+)/)?$///.exec(thread_url)
    unless tmp then return null
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

  parse_ch = (text) ->
    # name, mail, other, message, thread_title
    reg = /^(.*?)<>(.*?)<>(.*?)<>(.*?)<>(.*?)(?:<>)?$/

    thread = res: []
    first_flg = true
    for line in text.split("\n")
      reg_res = reg.exec(line)
      if reg_res
        if first_flg
          thread.title = app.util.decode_char_reference(reg_res[5])
          first_flg = false
        thread.res.push
          name: reg_res[1]
          mail: reg_res[2]
          message: reg_res[4]
          other: reg_res[3]
      else
        continue if line is ""
        thread.res.push
          name: "</b>データ破損<b>"
          mail: ""
          message: "データが破損しています"
          other: ""
    if thread.res.length > 0 then thread else null

  parse_machi = (text) ->
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
        thread.title = app.util.decode_char_reference(reg_res[6])
      thread.res.push
        name: reg_res[2]
        mail: reg_res[3]
        message: reg_res[5]
        other: reg_res[4]

    if thread.res.length > 0 then thread else null

  parse_jbbs = (text) ->
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
        thread.title = app.util.decode_char_reference(reg_res[6])
      thread.res.push
        name: reg_res[2]
        mail: reg_res[3]
        message: reg_res[5]
        other: reg_res[4] + if reg_res[7] then " ID:" + reg_res[7] else ""
    if thread.res.length > 0 then thread else null

  class Thread
    constructor: (@url) ->
      @title = null
      @res = null
      @message = null

    get: (force_update) ->
      url = @url

      res_deferred = $.Deferred()

      xhr_info = get_xhr_info(url)
      unless xhr_info then return res_deferred.reject().promise()
      xhr_path = xhr_info.path
      xhr_charset = xhr_info.charset

      cache = new Cache(xhr_path)
      delta_flg = false

      #キャッシュ取得
      promise_cache_get = cache.get()
      promise_cache_get.pipe =>
        $.Deferred (deferred) =>
          if force_update or Date.now() - cache.last_updated > 1000 * 3
            #通信が生じる場合のみ、notifyでキャッシュを送出する
            app.defer =>
              tmp = Thread.parse(@url, cache.data)
              @res = tmp.res
              @title = tmp.title
              res_deferred.notify()
              return
            deferred.reject()
          else
            deferred.resolve()
          return
      #通信
      .pipe null, ->
        $.Deferred (deferred) ->
          tmp_xhr_path = xhr_path
          if app.url.tsld(url) in ["livedoor.jp", "machi.to"]
            if promise_cache_get.isResolved()
              delta_flg = true
              tmp_xhr_path += (+cache.res_length + 1) + "-"

          ajax_data =
            url: tmp_xhr_path
            cache: false
            dataType: "text"
            headers: {}
            mimeType: "text/plain; charset=#{xhr_charset}"
            timeout: 1000 * 30
            complete: ($xhr) ->
              if $xhr.status is 200
                deferred.resolve($xhr)
              else if promise_cache_get.isResolved() and $xhr.status is 304
                deferred.resolve($xhr)
              else
                deferred.reject($xhr)

          if promise_cache_get.isResolved()
            if cache.last_modified?
              ajax_data.headers["If-Modified-Since"] = new Date(cache.last_modified).toUTCString()
            if cache.data.etag?
              ajax_data.headers["If-None-Match"] = cache.etag

          $.ajax(ajax_data)

      #パース
      .pipe((fn = ($xhr) =>
        $.Deferred (deferred) =>
          guess_res = app.url.guess_type(url)

          if $xhr?.status is 200
            if delta_flg
              thread = Thread.parse(@url, cache.data + $xhr.responseText)
            else
              thread = Thread.parse(@url, $xhr.responseText)
          #2ch系BBSのdat落ち
          else if guess_res.bbs_type is "2ch" and $xhr?.status is 203
            if promise_cache_get.isResolved()
              thread = Thread.parse(@url, cache.data)
            else
              thread = Thread.parse(@url, $xhr.responseText)
          else if promise_cache_get.isResolved()
            thread = Thread.parse(@url, cache.data)

          #パース成功
          if thread
            #通信成功
            if $xhr?.status is 200 or
                #通信成功（更新なし）
                $xhr?.status is 304 or
                #キャッシュが期限内だった場合
                (not $xhr and promise_cache_get.isResolved())
              deferred.resolve($xhr, thread)
            #2ch系BBSのdat落ち
            else if guess_res.bbs_type is "2ch" and $xhr?.status is 203
              deferred.reject($xhr, thread)
            else
              deferred.reject($xhr, thread)
          #パース失敗
          else
            deferred.reject($xhr)
      ), fn)

      #コールバック
      .always ($xhr, thread) =>
        if thread
          @title = thread.title
          @res = thread.res
        return

      .done ($xhr, thread) =>
        res_deferred.resolve()
        return

      .fail ($xhr, thread) =>
        @message = ""

        #2chでrejectされてる場合は移転を疑う
        if app.url.tsld(url) is "2ch.net" and $xhr
          app.util.ch_server_move_detect(app.url.thread_to_board(url))
            #移転検出時
            .done (new_board_url) =>
              tmp = ///^http://(\w+)\.2ch\.net/ ///.exec(new_board_url)[1]
              new_url = url.replace(
                ///^(http://)\w+(\.2ch\.net/test/read\.cgi/\w+/\d+/)$///,
                ($0, $1, $2) -> $1 + tmp + $2
              )

              @message += """
              スレッドの読み込みに失敗しました。
              サーバーが移転している可能性が有ります
              (<a href="#{app.escape_html(app.safe_href(new_url))}"
                class="open_in_rcrx">#{app.escape_html(new_url)}</a>)
              """
              return
            #移転検出出来なかった場合
            .fail =>
              if $xhr?.status is 203
                @message += "dat落ちしたスレッドです。"
              else
                @message += "スレッドの読み込みに失敗しました。"
              return
            .always =>
              if promise_cache_get.isResolved() and thread
                @message += "キャッシュに残っていたデータを表示します。"
              res_deferred.reject()
              return
        else
          @message += "スレッドの読み込みに失敗しました。"

          if promise_cache_get.isResolved() and thread
            @message += "キャッシュに残っていたデータを表示します。"

          res_deferred.reject()
        return

      #キャッシュ更新部
      .done ($xhr, thread) ->
        #通信に成功した場合
        if $xhr?.status is 200
          cache.last_updated = Date.now()
          cache.res_length = thread.res.length

          if delta_flg
            cache.data += $xhr.responseText
          else
            cache.data = $xhr.responseText

          last_modified = new Date(
            $xhr.getResponseHeader("Last-Modified") or "dummy"
          ).getTime()

          if not isNaN(last_modified)
            cache.last_modified = last_modified

          etag = $xhr.getResponseHeader("ETag")
          if etag
            cache.etag = etag

          cache.put()

        #304だった場合はアップデート時刻のみ更新
        else if promise_cache_get.isResolved() and $xhr?.status is 304
          cache.last_updated = Date.now()
          cache.put()

        return

      #ブックマーク更新部
      .always ($xhr, thread) ->
        if thread?
          if $xhr?.status is 200 or $xhr?.status is 203
            app.bookmark.update_res_count(url, thread.res.length)
        return

      #dat落ち検出
      .fail ($xhr, thread) ->
        if $xhr?.status is 203
          app.bookmark.update_expired(url, true)
        return

      res_deferred.promise()

    @parse: (url, text) ->
      switch app.url.tsld(url)
        when ""
          null
        when "machi.to"
          parse_machi(text)
        when "livedoor.jp"
          parse_jbbs(text)
        else
          parse_ch(text)

  callback(Thread)
