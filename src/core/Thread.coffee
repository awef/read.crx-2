###*
@namespace app
@class Thread
@constructor
@param {String} url
###
class app.Thread
  constructor: (url) ->
    @url = app.url.fix(url)
    @title = null
    @res = null
    @message = null
    @_cachePut = $.Deferred()
    return

  get: (forceUpdate) ->
    resDeferred = $.Deferred()

    xhrInfo = Thread._getXhrInfo(@url)
    unless xhrInfo then return resDeferred.reject().promise()
    xhrPath = xhrInfo.path
    xhrCharset = xhrInfo.charset

    getCachedInfo = $.Deferred (d) ->
      if app.url.tsld(@url) in ["livedoor.jp", "machi.to"]
        app.Board.get_cached_res_count(@url)
          .done (res) ->
            d.resolve(res)
            return
          .fail ->
            d.reject()
            return
      else
        d.reject()
      return

    cache = new app.Cache(xhrPath)
    deltaFlg = false

    #キャッシュ取得
    promiseCacheGet = cache.get()
    promiseCacheGet.pipe =>
      $.Deferred (d) =>
        if forceUpdate or Date.now() - cache.last_updated > 1000 * 3
          #通信が生じる場合のみ、notifyでキャッシュを送出する
          app.defer =>
            tmp = Thread.parse(@url, cache.data)
            return unless tmp?
            @res = tmp.res
            @title = tmp.title
            resDeferred.notify()
            return
          d.reject()
        else
          d.resolve()
        return
    #通信
    .pipe null, =>
      $.Deferred (d) =>
        if app.url.tsld(@url) in ["livedoor.jp", "machi.to"]
          if promiseCacheGet.state() is "resolved"
            deltaFlg = true
            xhrPath += (+cache.res_length + 1) + "-"

        ajaxData =
          url: xhrPath
          cache: false
          dataType: "text"
          headers: {}
          mimeType: "text/plain; charset=#{xhrCharset}"
          timeout: 1000 * 30
          complete: ($xhr) ->
            if $xhr.status is 200
              d.resolve($xhr)
            else if promiseCacheGet.state() is "resolved" and $xhr.status is 304
              d.resolve($xhr)
            else
              d.reject($xhr)

        if promiseCacheGet.state() is "resolved"
          if cache.last_modified?
            ajaxData.headers["If-Modified-Since"] =
              new Date(cache.last_modified).toUTCString()
          if cache.etag?
            ajaxData.headers["If-None-Match"] = cache.etag

        $.ajax(ajaxData)

    #パース
    .pipe((fn = ($xhr) =>
      $.Deferred (d) =>
        guessRes = app.url.guess_type(@url)

        if $xhr?.status is 200
          if deltaFlg
            thread = Thread.parse(@url, cache.data + $xhr.responseText)
          else
            thread = Thread.parse(@url, $xhr.responseText)
        #2ch系BBSのdat落ち
        else if guessRes.bbs_type is "2ch" and $xhr?.status is 203
          if promiseCacheGet.state() is "resolved"
            thread = Thread.parse(@url, cache.data)
          else
            thread = Thread.parse(@url, $xhr.responseText)
        else if promiseCacheGet.state() is "resolved"
          thread = Thread.parse(@url, cache.data)

        #パース成功
        if thread
          #通信成功
          if $xhr?.status is 200 or
              #通信成功（更新なし）
              $xhr?.status is 304 or
              #キャッシュが期限内だった場合
              (not $xhr and promiseCacheGet.state() is "resolved")
            d.resolve($xhr, thread)
          #2ch系BBSのdat落ち
          else if guessRes.bbs_type is "2ch" and $xhr?.status is 203
            d.reject($xhr, thread)
          else
            d.reject($xhr, thread)
        #パース失敗
        else
          d.reject($xhr)
    ), fn)

    #したらば/まちBBS最新レス削除対策
    .pipe ($xhr, thread) ->
      $.Deferred (d) ->
        getCachedInfo
          .done (cachedInfo) ->
            while thread.res.length < cachedInfo.res_count
              thread.res.push
                name: "あぼーん"
                mail: "あぼーん"
                message: "あぼーん"
                other: "あぼーん"
            d.resolve($xhr, thread)
            return
          .fail ->
            d.resolve($xhr, thread)
            return
        return

    #コールバック
    .always ($xhr, thread) =>
      if thread
        @title = thread.title
        @res = thread.res
      return

    .done ($xhr, thread) =>
      resDeferred.resolve()
      return

    .fail ($xhr, thread) =>
      @message = ""

      #2chでrejectされてる場合は移転を疑う
      if app.url.tsld(@url) is "2ch.net" and $xhr
        app.util.ch_server_move_detect(app.url.thread_to_board(@url))
          #移転検出時
          .done (newBoardURL) =>
            tmp = ///^http://(\w+)\.2ch\.net/ ///.exec(newBoardURL)[1]
            newURL = @url.replace(
              ///^(http://)\w+(\.2ch\.net/test/read\.cgi/\w+/\d+/)$///,
              ($0, $1, $2) -> $1 + tmp + $2
            )

            @message += """
            スレッドの読み込みに失敗しました。
            サーバーが移転している可能性が有ります
            (<a href="#{app.escape_html(app.safe_href(newURL))}"
              class="open_in_rcrx">#{app.escape_html(newURL)}</a>)
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
            if promiseCacheGet.state() is "resolved" and thread
              @message += "キャッシュに残っていたデータを表示します。"
            resDeferred.reject()
            return
      else
        @message += "スレッドの読み込みに失敗しました。"

        if promiseCacheGet.state() is "resolved" and thread
          @message += "キャッシュに残っていたデータを表示します。"

        resDeferred.reject()
      return

    #キャッシュ更新部
    .done ($xhr, thread) =>
      #通信に成功した場合
      if $xhr?.status is 200
        cache.last_updated = Date.now()
        cache.res_length = thread.res.length

        if deltaFlg
          cache.data += $xhr.responseText
        else
          cache.data = $xhr.responseText

        lastModified = new Date(
          $xhr.getResponseHeader("Last-Modified") or "dummy"
        ).getTime()

        if not isNaN(lastModified)
          cache.last_modified = lastModified

        etag = $xhr.getResponseHeader("ETag")
        if etag
          cache.etag = etag

        cache.put().done => @_cachePut.notify("done"); return

      #304だった場合はアップデート時刻のみ更新
      else if promiseCacheGet.state() is "resolved" and $xhr?.status is 304
        cache.last_updated = Date.now()
        cache.put().done => @_cachePut.notify("done"); return
      return

    .fail =>
      @_cachePut.notify("unexecuted")
      return

    #ブックマーク更新部
    .always ($xhr, thread) =>
      if thread?
        app.bookmark.update_res_count(@url, thread.res.length)
      return

    #dat落ち検出
    .fail ($xhr, thread) =>
      if $xhr?.status is 203
        app.bookmark.update_expired(@url, true)
      return

    resDeferred.promise()

  ###*
  @method _getXhrInfo
  @static
  @param {String} url
  @return {null|Object}
  ###
  @_getXhrInfo = (url) ->
    tmp = ///^http://(\w+\.(\w+\.\w+))/(?:test|bbs)/read\.cgi/
      (\w+)/(\d+)/(?:(\d+)/)?$///.exec(url)
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

  ###*
  @method parse
  @static
  @param {String} url
  @param {String} text
  @return {null|Object}
  ###
  @parse: (url, text) ->
    switch app.url.tsld(url)
      when ""
        null
      when "machi.to"
        Thread._parseMachi(text)
      when "livedoor.jp"
        Thread._parseJbbs(text)
      else
        Thread._parseCh(text)

  ###*
  @method _parseCh
  @static
  @private
  @param {String} text
  @return {null|Object}
  ###
  @_parseCh = (text) ->
    # name, mail, other, message, thread_title
    reg = /^(.*?)<>(.*?)<>(.*?)<>(.*?)<>(.*?)(?:<>)?$/
    numberOfBroken = 0
    thread = res: []
    first = true

    for line, key in text.split("\n")
      regRes = reg.exec(line)
      if regRes
        if key is 0
          thread.title = app.util.decode_char_reference(regRes[5])

        thread.res.push
          name: regRes[1]
          mail: regRes[2]
          message: regRes[4]
          other: regRes[3]
      else
        continue if line is ""
        numberOfBroken++
        thread.res.push
          name: "</b>データ破損<b>"
          mail: ""
          message: "データが破損しています"
          other: ""

    if thread.res.length > 0 and thread.res.length > numberOfBroken
      thread
    else
      null

  ###*
  @method _parseMachi
  @static
  @private
  @param {String} text
  @return {null|Object}
  ###
  @_parseMachi = (text) ->
    # res_num, name, mail, other, message, thread_title
    reg = /^(\d+)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm
    thread = {res: []}
    resCount = 0

    while regRes = reg.exec(text)
      while ++resCount isnt +regRes[1]
        thread.res.push
          name: "あぼーん"
          mail: "あぼーん"
          message: "あぼーん"
          other: "あぼーん"

      if resCount is 1
        thread.title = app.util.decode_char_reference(regRes[6])

      thread.res.push
        name: regRes[2]
        mail: regRes[3]
        message: regRes[5]
        other: regRes[4]

    if thread.res.length > 0 then thread else null

  ###*
  @method _parseJbbs
  @static
  @private
  @param {String} text
  @return {null|Object}
  ###
  @_parseJbbs = (text) ->
    # res_num, name, mail, date, message, thread_title, id
    reg = /^(\d+)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm
    thread = {res: []}
    resCount = 0

    while regRes = reg.exec(text)
      while ++resCount isnt +regRes[1]
        thread.res.push
          name: "あぼーん"
          mail: "あぼーん"
          message: "あぼーん"
          other: "あぼーん"

      if resCount is 1
        thread.title = app.util.decode_char_reference(regRes[6])

      thread.res.push
        name: regRes[2]
        mail: regRes[3]
        message: regRes[5]
        other: regRes[4] + if regRes[7] then " ID:" + regRes[7] else ""

    if thread.res.length > 0 then thread else null
