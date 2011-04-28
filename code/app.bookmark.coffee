`/** @namespace */`
app.bookmark = {}

(->
  source_id = app.config.get("bookmark_id")
  bookmark_data = []
  bookmark_data_index_url = {}
  bookmark_data_index_id = {}
  watcher_wakeflg = true

  hoge_bookmark = (bookmark_node) ->
    guess_res = app.url.guess_type(bookmark_node.url)
    if guess_res.type is "board" or guess_res.type is "thread"
      url = app.url.fix(bookmark_node.url)
      bookmark_data.push
        type: guess_res.type
        bbs_type: guess_res.bbs_type
        url: url
        title: bookmark_node.title
        res_count: null
        read: null
        last: null
      bookmark_data_index_url[url] = bookmark_data.length - 1
      bookmark_data_index_id[bookmark_node.id] = bookmark_data.length - 1

  update_all = () ->
    try
      chrome.bookmarks.getChildren source_id, (array_of_tree) ->
        bookmark_data = []
        bookmark_data_index_url = {}
        bookmark_data_index_id = {}
        for tree in array_of_tree
          if "url" of tree
            hoge_bookmark(tree)
    catch e
      $(-> app.view.open_bookmark_source_selector())

  chrome.bookmarks.onImportBegan.addListener ->
    watcher_wakeflg = false

  chrome.bookmarks.onImportEnded.addListener ->
    watcher_wakeflg = true
    update_all()

  chrome.bookmarks.onCreated.addListener (id, node) ->
    if watcher_wakeflg and node.parentId is source_id and "url" of node
      hoge_bookmark(node)

  chrome.bookmarks.onRemoved.addListener (id, e) ->
    if watcher_wakeflg and id of bookmark_data_index_id
      update_all()

  chrome.bookmarks.onChanged.addListener (id, e) ->
    if watcher_wakeflg and id of bookmark_data_index_id
      update_all()

  chrome.bookmarks.onMoved.addListener (id, e) ->
    if watcher_wakeflg
      if e.parentId is source_id or e.oldParentId is source_id
        update_all()

  update_all()

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

  app.bookmark.change_source = (new_source_id) ->
    app.config.set("bookmark_id", new_source_id)
    source_id = new_source_id
    update_all()
)()
