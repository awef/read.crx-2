if localStorage.zombie_read_state?
  array_of_read_state = JSON.parse(localStorage["zombie_read_state"])
  for read_state in array_of_read_state
    url_list = []
    url_list.push(read_state.url)

  #TODO ちゃんとした名前を付ける
  hoge = (url) ->
    index = url_list.indexOf(url)
    if index isnt -1
      url_list.splice(index, 1)
      if url_list.length is 0
        close()

  app.message.add_listener "read_state_updated", (message) ->
    if not app.bookmark.get(message.read_state.url)
      hoge(message.read_state.url)

  chrome.bookmarks.onChanged.addListener (id, prop) ->
    hoge(app.url.fix(prop.url))

  for read_state in array_of_read_state
    app.read_state.set(read_state)

  delete localStorage["zombie_read_state"]
else
  close()
