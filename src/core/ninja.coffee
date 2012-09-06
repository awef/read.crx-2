###*
@namespace app
@class Ninja
@static
###
class app.Ninja
  @_siteInfo =
    "2ch":
      siteId: "2ch"
      siteName: "2ちゃんねる"
      cookieInfo: {url: "http://www.2ch.net/", name: "HAP"}

  ###*
  @method getCookie
  @static
  @param {Function} callback
  ###
  @getCookie: (callback) ->
    site = @_siteInfo["2ch"]

    chrome.cookies.get site.cookieInfo, (res) ->
      data = []
      if res
        data.push({site, value: res.value})
      callback(data)
      return
    return

  ###*
  @method deleteCookie
  @static
  @param {String} siteId
  @param {Function} [callback]
  ###
  @deleteCookie: (siteId, callback) ->
    chrome.cookies.remove @_siteInfo[siteId].cookieInfo, ->
      callback?()
      return
    return

###
app.ninja.get_info_stored = ->
  data = []
  for site_id, site of app.ninja._site_info
    tmp = app.config.get("ninja_store_#{site_id}")
    if tmp
      data.push({site, value: JSON.parse(tmp).value})

  $.Deferred().resolve(data).promise()

app.ninja.store_cookie = (site_id) ->
  $.Deferred (deferred) ->
    chrome.cookies.get app.ninja._site_info[site_id].cookie_info, (cookie) ->
      if cookie
        app.config.set("ninja_store_#{site_id}", JSON.stringify(cookie))
        deferred.resolve()
      else
        deferred.reject()
  .promise()

app.ninja.restore_cookie = (site_id) ->
  $.Deferred (deferred) ->
    tmp = app.config.get("ninja_store_#{site_id}")
    if tmp
      backup = JSON.parse(tmp)
      backup.url = app.ninja._site_info[site_id].cookie_info.url
      delete backup.hostOnly
      delete backup.session
      chrome.cookies.set backup, ->
        deferred.resolve()
    else
      deferred.reject()
  .promise()

app.ninja.delete_stored_cookie = (site_id) ->
  app.config.del("ninja_store_#{site_id}")

  $.Deferred().resolve().promise()
###
