app.ninja = {}

app.ninja._site_info =
  "2ch":
    site_id: "2ch"
    site_name: "2ちゃんねる"
    cookie_info: {url: "http://www.2ch.net/", name: "HAP"}

  "bbspink":
    site_id: "bbspink"
    site_name: "BBSPINK"
    cookie_info: {url: "http://www.bbspink.com/", name: "HAP"}

app.ninja.get_info_cookie = ->
  data = []
  promises = []

  for site_id, site of app.ninja._site_info
    ((site) ->
      promises.push $.Deferred((deferred) ->
        chrome.cookies.get site.cookie_info, (res) ->
          if res
            data.push({site, value: res.value})
          deferred.resolve()
      ).promise()
    )(site)

  $.when.apply(this, promises)
    .pipe ->
      $.Deferred().resolve(data)

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

app.ninja.delete_cookie = (site_id) ->
  $.Deferred (deferred) ->
    chrome.cookies.remove app.ninja._site_info[site_id].cookie_info, ->
      deferred.resolve()
  .promise()

app.ninja.delete_stored_cookie = (site_id) ->
  app.config.del("ninja_store_#{site_id}")

  $.Deferred().resolve().promise()
