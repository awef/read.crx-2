app.bookmark = {}

(->
  bookmark_data = []
  bookmark_data_index_url = {}

  bookmark_id = app.config.get("bookmark_id")

  update_all = ->
    chrome.bookmarks.getChildren bookmark_id, (array_of_tree) ->
      for tree in array_of_tree
        if "url" of tree
          tmp = app.url.guess_type(tree.url)
          if tmp.type is "board" or tmp.type is "thread"
            url = app.url.fix(tree.url)
            bookmark_data.push(
              type: tmp.type
              bbs_type: tmp.bbs_type
              url: url
              title: tree.title
              res_count: null
              read: null
              last: null
            )
            bookmark_data_index_url[url] = bookmark_data.length - 1

  if typeof bookmark_id is "string"
    update_all()

  app.bookmark.get = (url) ->
    if url of bookmark_data_index_url
      bookmark_data[bookmark_data_index_url[url]]
    else
      null

  app.bookmark.get_all = ->
    app.deep_copy(bookmark_data)
)()
