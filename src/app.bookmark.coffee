app.bookmark = {}

(->
  source_id = app.config.get("bookmark_id")

  #ブックマークの状態を管理する処理群
  empty_awef =
    data: []
    index_url: {} #urlからdataのキーを導く
    index_id: {} #idからdataのキーを導く
    index_url_id: {} #urlからidを導く
    index_board_url: {} #板urlからキーの配列を導く

  scan_awef = ->
    $.Deferred (deferred) ->
      tmp_awef = app.deep_copy(empty_awef)
      try
        chrome.bookmarks.getChildren source_id, (array_of_tree) ->
          for tree in array_of_tree
            if "url" of tree
              guess_res = app.url.guess_type(tree.url)
              if guess_res.type is "board" or guess_res.type is "thread"
                url = app.url.fix(tree.url)
                tmp_bookmark =
                  type: guess_res.type
                  bbs_type: guess_res.bbs_type
                  url: url
                  title: tree.title
                  res_count: null

                arg = app.url.parse_hashquery(tree.url)
                if /^\d+$/.test(arg.res_count)
                  tmp_bookmark.res_count = +arg.res_count

                if (
                  /^\d+$/.test(arg.received) and
                  /^\d+$/.test(arg.read) and
                  /^\d+$/.test(arg.last)
                )
                  tmp_bookmark.read_state =
                    url: url
                    received: +arg.received
                    read: +arg.read
                    last: +arg.last

                if arg.expired is true
                  tmp_bookmark.expired = true

                tmp_awef.data.push(tmp_bookmark)
                key = tmp_awef.data.length - 1
                tmp_awef.index_url[url] = key
                tmp_awef.index_id[tree.id] = key
                tmp_awef.index_url_id[url] = tree.id
                board_url = app.url.thread_to_board(url)
                tmp_awef.index_board_url[board_url] or= []
                tmp_awef.index_board_url[board_url].push(key)
          deferred.resolve(tmp_awef)

      catch e
        $(-> app.view_bookmark_source_selector.open())
        deferred.reject()
    .promise()

  now_awef = app.deep_copy(empty_awef)

  update_awef = (new_awef) ->
    old_awef = now_awef or app.deep_copy(empty_awef)

    #追加されたブックマークの検出
    for new_bookmark in new_awef.data
      if not (new_bookmark.url of old_awef.index_url)
        app.message.send("bookmark_updated",
          {type: "added", bookmark: new_bookmark})

    #削除されたブックマークの抽出
    for old_bookmark in old_awef.data
      if not (old_bookmark.url of new_awef.index_url)
        app.message.send("bookmark_updated",
          {type: "removed", bookmark: old_bookmark})

    now_awef = new_awef

  update_all = ->
    scan_awef().done (new_awef) ->
      update_awef(new_awef)

  update_all()

  #実際のブックマークの変更を検出して更新処理を呼ぶ処理群
  watcher_wakeflg = true

  chrome.bookmarks.onImportBegan.addListener ->
    watcher_wakeflg = false

  chrome.bookmarks.onImportEnded.addListener ->
    watcher_wakeflg = true
    update_all()

  chrome.bookmarks.onCreated.addListener (id, node) ->
    if watcher_wakeflg and node.parentId is source_id and "url" of node
      update_all()

  chrome.bookmarks.onRemoved.addListener (id, e) ->
    if watcher_wakeflg and id of now_awef.index_id
      update_all()

  chrome.bookmarks.onChanged.addListener (id, e) ->
    if watcher_wakeflg and id of now_awef.index_id
      update_all()

  chrome.bookmarks.onMoved.addListener (id, e) ->
    if watcher_wakeflg
      if e.parentId is source_id or e.oldParentId is source_id
        update_all()

  # read.crxが実際にブックマークの取得/操作等を行うための関数群

  # ##app.bookmark.get
  # 与えられたURLがブックマークされていた場合はbookmarkオブジェクトを  
  # そうでなかった場合はnullを返す
  app.bookmark.get = (url) ->
    if url of now_awef.index_url
      app.deep_copy(now_awef.data[now_awef.index_url[url]])
    else
      null

  # ##app.bookmark.get_all
  # 全てのbookmarkを格納した配列を返す
  app.bookmark.get_all = ->
    app.deep_copy(now_awef.data)

  app.bookmark.get_by_board = (board_url) ->
    data = []
    for key in now_awef.index_board_url[board_url] or []
      data.push(now_awef.data[key])
    app.deep_copy(data)

  app.bookmark.change_source = (new_source_id) ->
    if app.assert_arg("app.bookmark.change_source", ["string"], arguments)
      return

    app.config.set("bookmark_id", new_source_id)
    source_id = new_source_id
    update_all()

  app.bookmark.add = (url, title) ->
    if app.assert_arg("app.bookmark.add", ["string", "string"], arguments)
      return

    unless url of now_awef.index_url
      url = app.url.fix(url)
      app.read_state.get(url).done (read_state) ->
        if read_state
          data =
            read: read_state.read
            last: read_state.last
            received: read_state.received
            res_count: read_state.received
          url += "#" + app.url.build_param(data)
        chrome.bookmarks.create({parentId: source_id, url, title})
    else
      app.log("error", "app.bookmark.add: 既にブックマークされいてるURLをブックマークに追加しようとしています", arguments)

  app.bookmark.remove = (url) ->
    if app.assert_arg("app.bookmark.remove", ["string"], arguments)
      return

    id = now_awef.index_url_id[app.url.fix(url)]
    if typeof id is "string"
      chrome.bookmarks.remove(id)
    else
      app.log("error", "app.bookmark.remove: ブックマークされていないURLをブックマークから削除しようとしています", arguments)

  app.bookmark.update_read_state = (read_state) ->
    url = read_state.url
    if bookmark = app.bookmark.get(url)
      if bookmark.read_state and
          bookmark.read_state.received is read_state.received and
          bookmark.read_state.read is read_state.read and
          bookmark.read_state.last is read_state.last
        return

      data =
        received: read_state.received
        read: read_state.read
        last: read_state.last

      if bookmark.res_count
        data.res_count = bookmark.res_count

      if bookmark.expired is true
        data.expired = true

      chrome.bookmarks.update(now_awef.index_url_id[url],
        url: read_state.url + "#" + app.url.build_param(data))

  app.bookmark.update_res_count = (url, res_count) ->
    if bookmark = app.bookmark.get(url)
      if bookmark.res_count is res_count
        return

      data = {res_count}

      if bookmark.read_state
        data.received = bookmark.read_state.received
        data.read = bookmark.read_state.read
        data.last = bookmark.read_state.last

      if bookmark.expired is true
        data.expired = true

      chrome.bookmarks.update(now_awef.index_url_id[url],
        url: url + "#" + app.url.build_param(data))

  app.bookmark.update_expired = (url, expired) ->
    if bookmark = app.bookmark.get(url)
      data = {}

      if expired is true
        data.expired = true

      if bookmark.read_state
        data.received = bookmark.read_state.received
        data.read = bookmark.read_state.read
        data.last = bookmark.read_state.last

      if bookmark.res_count
        data.res_count = bookmark.res_count

      chrome.bookmarks.update(now_awef.index_url_id[url],
        url: url + "#" + app.url.build_param(data))
 )()
