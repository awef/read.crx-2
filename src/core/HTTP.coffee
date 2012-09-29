app.HTTP = {}

###*
@class app.HTTP.Request
@constructor
@param {String} method
@param {String} url
@param {Object} [params]
  @param {String} [params.mimeType]
  @param {Object} [params.headers]
  @param {String} [params.timeout]
  @param {Boolean} [params.preventCache]
###
class app.HTTP.Request
  ###*
  @property {String} method
  ###

  ###*
  @property {String} url
  ###
  constructor: (@method, @url, params = {}) ->
    ###*
    @property {String} mimeType
    ###
    @mimeType = params.mimeType or null

    ###*
    @property {Number} timeout
    ###
    @timeout = params.timeout or 30000

    ###*
    @property {Object} headers
    ###
    @headers = params.headers or {}

    ###*
    @property {Boolean} preventCache
    ###
    @preventCache = params.preventCache or false
    return

  ###*
  @method send
  @param {Function} callback
  ###
  send: (callback) ->
    if @preventCache
      if res = /\?(.*)$/.exec(@url)
        if res[1].length > 0
          @url += "&_=#{Date.now()}"
        else
          @url += "_=#{Date.now()}"
      else
        @url += "?_=#{Date.now()}"

    xhr = new XMLHttpRequest()
    timer = setTimeout(xhr.abort.bind(xhr), @timeout)

    xhr.open(@method, @url)

    if @mimeType?
      xhr.overrideMimeType(@mimeType)

    for key, val of @headers
      xhr.setRequestHeader(key, val)

    xhr.addEventListener "loadend", ->
      clearTimeout(timer)

      resonseHeaders = Request.parseHTTPHeader(@getAllResponseHeaders())

      callback(new app.HTTP.Response(@status, resonseHeaders, @responseText))
      return

    xhr.send()
    @_xhr = xhr
    return

  ###*
  @method abort
  ###
  abort: ->
    @_xhr.abort()
    return

  ###*
  @method parseHTTPHeader
  @static
  @param {String}
  @return {Object}
  TODO 複数行ヘッダの挙動検証
  ###
  @parseHTTPHeader: (string) ->
    reg = /^(?:([a-z\-]+):\s*|([ \t]+))(.+)\s*$/gim
    headers = {}
    last = null

    while res = reg.exec(string)
      if res[1]?
        headers[res[1]] = res[3]
        last = res[1]
      else if last?
        headers[last] += res[2] + res[3]

    headers

###*
@class app.HTTP.Response
@constructor
@param {Number} status
@param {Object} [headers]
@param {null|String} [body]
###

###*
@property {Number} status
###

###*
@property {Object} headers
###

###*
@property {null|String} body
###
class app.HTTP.Response
  constructor: (@status, @headers = {}, @body = null) -> return
