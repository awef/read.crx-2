if "zombie_read_state" of localStorage
  array_of_read_state = JSON.parse(localStorage["zombie_read_state"])
  for read_state in array_of_read_state
    url_list = []
    url_list.push(read_state.url)

  chrome.bookmarks.onChanged.addListener (id, prop) ->
    index = url_list.indexOf(app.url.fix(prop.url))
    if index isnt -1
      url_list.splice(index, 1)
      if url_list.length is 0
        close()

  for read_state in array_of_read_state
    app.read_state.set(read_state)

  delete localStorage["zombie_read_state"]
else
  close()
