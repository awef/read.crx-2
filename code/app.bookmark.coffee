`/** @namespace */`
app.bookmark = {}

(->
  bookmark_data = []
  bookmark_data_index_url = {}

  update_all = (bookmark_id) ->
    chrome.bookmarks.getChildren bookmark_id, (array_of_tree) ->
      for tree in array_of_tree
        if "url" of tree
          tmp = app.url.guess_type(tree.url)
          if tmp.type is "board" or tmp.type is "thread"
            url = app.url.fix(tree.url)
            bookmark_data.push
              type: tmp.type
              bbs_type: tmp.bbs_type
              url: url
              title: tree.title
              res_count: null
              read: null
              last: null
            bookmark_data_index_url[url] = bookmark_data.length - 1

  tmp = app.config.get("bookmark_id")
  if typeof tmp is "string"
    update_all(tmp)
  else
    $(-> app.view.open_bookmark_source_selector())

  `/**
   * 与えられたURLがブックマークされていた場合はbookmarkオブジェクトを
   * そうでなかった場合はnullを返す
   * @param {fixed_url}
   * @returns {bookmark}
   * @returns {null}
   */`
  app.bookmark.get = (url) ->
    if url of bookmark_data_index_url
      bookmark_data[bookmark_data_index_url[url]]
    else
      null

  `/** @return {array of bookmark} */`
  app.bookmark.get_all = ->
    app.deep_copy(bookmark_data)
)()
