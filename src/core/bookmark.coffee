app.bookmark = {}

app.bookmark._deferred_first_scan = $.Deferred()
app.bookmark.promise_first_scan = app.bookmark._deferred_first_scan.promise()
(->
  source_id = app.config.get("bookmark_id")

  #ブックマークの状態を管理する処理群
  empty_cache =
    data: []
    index_url: {} #urlからdataのキーを導く
    index_id: {} #idからdataのキーを導く
    index_url_id: {} #urlからidを導く
    index_board_url: {} #板urlからキーの配列を導く

  scan_cache = ->
    $.Deferred (deferred) ->
      tmp_cache = app.deep_copy(empty_cache)
      try
        chrome.bookmarks.getChildren source_id, (array_of_tree) ->
          for tree in array_of_tree
            if tree.url?
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

                tmp_cache.data.push(tmp_bookmark)
                key = tmp_cache.data.length - 1
                tmp_cache.index_url[url] = key
                tmp_cache.index_id[tree.id] = key
                tmp_cache.index_url_id[url] = tree.id
                if tmp_bookmark.type is "thread"
                  board_url = app.url.thread_to_board(url)
                  tmp_cache.index_board_url[board_url] or= []
                  tmp_cache.index_board_url[board_url].push(key)
          deferred.resolve(tmp_cache)

      catch e
        app.message.send("open", url: "bookmark_source_selector")
        deferred.reject()
    .promise()

  now_cache = app.deep_copy(empty_cache)

  update_cache = (new_cache) ->
    old_cache = now_cache or app.deep_copy(empty_cache)

    #追加されたブックマークの検出
    for new_bookmark in new_cache.data
      if not old_cache.index_url[new_bookmark.url]?
        app.message.send("bookmark_updated",
          {type: "added", bookmark: new_bookmark})

      else if new_bookmark.expired isnt old_cache.data[old_cache.index_url[new_bookmark.url]].expired
        app.message.send("bookmark_updated",
          {type: "expired", bookmark: new_bookmark})

    #削除されたブックマークの抽出
    for old_bookmark in old_cache.data
      if not new_cache.index_url[old_bookmark.url]?
        app.message.send("bookmark_updated",
          {type: "removed", bookmark: old_bookmark})

    now_cache = new_cache

  update_all = ->
    scan_cache()
      .done (new_cache) ->
        update_cache(new_cache)
        unless app.bookmark._deferred_first_scan.isResolved() or
            app.bookmark._deferred_first_scan.isRejected()
          app.bookmark._deferred_first_scan.resolve()

      .fail ->
        unless app.bookmark._deferred_first_scan.isResolved() or
            app.bookmark._deferred_first_scan.isRejected()
          app.bookmark._deferred_first_scan.reject()

  update_all()

  #実際のブックマークの変更を検出して更新処理を呼ぶ処理群
  watcher_wakeflg = true

  chrome.bookmarks.onImportBegan.addListener ->
    watcher_wakeflg = false

  chrome.bookmarks.onImportEnded.addListener ->
    watcher_wakeflg = true
    update_all()

  chrome.bookmarks.onCreated.addListener (id, node) ->
    if watcher_wakeflg and node.parentId is source_id and node.url?
      update_all()

  chrome.bookmarks.onRemoved.addListener (id, e) ->
    if watcher_wakeflg and now_cache.index_id[id]?
      update_all()

  chrome.bookmarks.onChanged.addListener (id, e) ->
    if watcher_wakeflg and now_cache.index_id[id]?
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
    if now_cache.index_url[url]?
      app.deep_copy(now_cache.data[now_cache.index_url[url]])
    else
      null

  # ##app.bookmark.get_all
  # 全てのbookmarkを格納した配列を返す
  app.bookmark.get_all = ->
    app.deep_copy(now_cache.data)

  app.bookmark.get_by_board = (board_url) ->
    data = []
    for key in now_cache.index_board_url[board_url] or []
      data.push(now_cache.data[key])
    app.deep_copy(data)

  app.bookmark.change_source = (new_source_id) ->
    if app.assert_arg("app.bookmark.change_source", ["string"], arguments)
      return

    app.config.set("bookmark_id", new_source_id)
    source_id = new_source_id
    update_all()

  #res_countはオプショナル
  app.bookmark.add = (url, title, res_count) ->
    deferred = $.Deferred()
    promise = deferred.promise()

    if app.assert_arg("app.bookmark.add", ["string", "string"], arguments)
      deferred.reject()
    else if not now_cache.index_url[url]?
      url = app.url.fix(url)
      app.read_state.get(url).done (read_state) ->
        data = {}

        if read_state
          data.read = read_state.read
          data.last = read_state.last
          data.received =  read_state.received
          data.res_count = read_state.received

        if res_count?
          data.res_count = res_count

        url += "#" + app.url.build_param(data)
        chrome.bookmarks.create {parentId: source_id, url, title}, ->
          deferred.resolve()
    else
      app.log("error", "app.bookmark.add: 既にブックマークされいてるURLをブックマークに追加しようとしています", arguments)
      deferred.reject()
    return promise

  app.bookmark.remove = (url) ->
    deferred = $.Deferred()
    promise = deferred.promise()

    if app.assert_arg("app.bookmark.remove", ["string"], arguments)
      deferred.reject()
    else
      id = now_cache.index_url_id[app.url.fix(url)]
      if typeof id is "string"
        chrome.bookmarks.remove id, -> deferred.resolve()
      else
        app.log("error", "app.bookmark.remove: ブックマークされていないURLをブックマークから削除しようとしています", arguments)
        deferred.reject()
    return promise

  app.bookmark.update_read_state = (read_state) ->
    $.Deferred (deferred) ->
      read_state = app.deep_copy(read_state)
      url = read_state.url
      if bookmark = app.bookmark.get(url)
        if bookmark.read_state and
            bookmark.read_state.received is read_state.received and
            bookmark.read_state.read is read_state.read and
            bookmark.read_state.last is read_state.last
          deferred.resolve()
          return

        data =
          received: read_state.received
          read: read_state.read
          last: read_state.last

        if bookmark.res_count
          data.res_count = bookmark.res_count

        if bookmark.expired is true
          data.expired = true

        chrome.bookmarks.update(
          now_cache.index_url_id[url],
          url: read_state.url + "#" + app.url.build_param(data),
          ->
            deferred.resolve()
        )
      else
        deferred.reject()
    .promise()

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

      chrome.bookmarks.update(now_cache.index_url_id[url],
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

      chrome.bookmarks.update(now_cache.index_url_id[url],
        url: url + "#" + app.url.build_param(data))

  #dat落ち検出時の処理
  app.message.add_listener "detected_removed_dat", (message) ->
    app.bookmark.update_expired(message.url, true)

  #鯖移転検出時の処理
  app.message.add_listener "detected_ch_server_move", (message) ->
    #板ブックマークの更新
    if bookmark = app.bookmark.get(message.before)
      app.bookmark.remove(message.before)
      app.bookmark.add(message.after, bookmark.title)

    #スレブックマークの更新
    tmp = ///^http://(\w+)\.2ch\.net/ ///.exec(message.after)[1]
    for bookmark in app.bookmark.get_by_board(message.before)
      app.bookmark.remove(bookmark.url)
      bookmark.url = bookmark.url.replace(
        ///^(http://)\w+(\.2ch\.net/test/read\.cgi/\w+/\d+/)$///,
        ($0, $1, $2) -> $1 + tmp + $2
      )

      app.bookmark.add(bookmark.url, bookmark.title)

      if bookmark.read_state?
        bookmark.read_state.url = bookmark.url
        app.bookmark.update_read_state(bookmark.read_state)

      if bookmark.res_count?
        app.bookmark.update_res_count(bookmark.url, bookmark.res_count)

      if bookmark.expired?
        app.bookmark.update_expired(bookmark.url, bookmark.expired)
    return
)()
