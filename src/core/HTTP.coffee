app.HTTP = {}

###*
@namespace app.HTTP
@class app.HTTP.Request
@constructor
###
class app.HTTP.Request
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
