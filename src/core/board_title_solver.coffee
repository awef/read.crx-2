###*
@namespace app
@class BoardTitleSolver
@static
@require app.BBSMenu
@require jQuery
###
class app.BoardTitleSolver
  ###*
  @property _bbsmenu
  @type Object | null
  ###
  @_bbsmenu: null

  ###*
  @method getBBSMenu
  @return {Promise}
  ###
  @getBBSMenu: ->
    $.Deferred((d) =>
      if @_bbsmenu?
        d.resolve(@_bbsmenu)
      else
        app.BBSMenu.get (result) =>
          if result.data?
            @_bbsmenu = {}
            for category in result.data
              for board in category.board
                @_bbsmenu[board.url] = board.title
            d.resolve(@_bbsmenu)
          else
            d.reject()
          return
      return
    )
    .promise()

  ###*
  @method searchFromBBSMenu
  @param {String} url
  @return {Promise}
  ###
  @searchFromBBSMenu: (url) ->
    @getBBSMenu().pipe((bbsmenu) => $.Deferred (d) =>
      if bbsmenu[url]?
        d.resolve(bbsmenu[url])
      else
        d.reject()
      return
    )
    .promise()

  ###*
  @method searchFromBookmark
  @param {String} url
  @return {Promise}
  ###
  @searchFromBookmark: (url) ->
    $.Deferred((d) ->
      if bookmark = app.bookmark.get(url)
        if app.url.tsld(bookmark.url) is "2ch.net"
          d.resolve(bookmark.title.replace("＠2ch掲示板", ""))
        else
          d.resolve(bookmark.title)
      else
        d.reject()
      return
    )
    .promise()

  ###*
  @method searchFromSettingTXT
  @param {String} url
  @return {Promise}
  ###
  @searchFromSettingTXT: (url) ->
    $.ajax(url + "SETTING.TXT", {
      dataType: "text"
      timeout: 1000 * 10
      beforeSend: (jqxhr) ->
        jqxhr.overrideMimeType("text/plain; charset=Shift_JIS")
        return
    })
    .pipe(
      (text) ->
        $.Deferred (d) ->
          if res = /^BBS_TITLE=(.+)$/m.exec(text)
            d.resolve(res[1].replace("＠2ch掲示板", ""))
          else
            d.reject()
          return
      ->
        $.Deferred().reject()
    )
    .promise()

  ###*
  @method searchFromJbbsAPI
  @param {String} url
  @return {Promise}
  ###
  @searchFromJbbsAPI: (url) ->
    tmp = url.split("/")
    ajax_path = "http://jbbs.livedoor.jp/bbs/api/setting.cgi/#{tmp[3]}/#{tmp[4]}/"

    $.ajax(ajax_path, {
      dataType: "text"
      timeout: 1000 * 10
      beforeSend: (jqxhr) ->
        jqxhr.overrideMimeType("text/plain; charset=EUC-JP")
        return
    })
    .pipe(
      (text) ->
        $.Deferred (d) ->
          if res = /^BBS_TITLE=(.+)$/m.exec(text)
            d.resolve(res[1])
          else
            d.reject()
          return
      ->
        $.Deferred().reject()
    )
    .promise()

  ###*
  @method ask
  @param {Object} prop
    @param {String} prop.url
    @param {Boolean} [prop.offline]
  @return Promise
  ###
  @ask: (prop) ->
    url = app.url.fix(prop.url)

    #bbsmenu内を検索
    @searchFromBBSMenu(url)
      #ブックマーク内を検索
      .pipe(null, => @searchFromBookmark(url))
      #SETTING.TXTからの取得を試みる
      .pipe(null, =>
        if not prop.offline and app.url.guess_type(url).bbs_type is "2ch"
          @searchFromSettingTXT(url)
      )
      #したらばのAPIから取得を試みる
      .pipe(null, =>
        if not prop.offline and app.url.guess_type(url).bbs_type is"jbbs"
          @searchFromJbbsAPI(url)
      )
      .promise()

app.module "board_title_solver", [], (callback) ->
  callback(app.BoardTitleSolver)
  return
