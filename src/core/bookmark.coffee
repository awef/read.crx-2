app.bookmark = {}

app.bookmark._deferred_first_scan = $.Deferred()
app.bookmark.promise_first_scan = app.bookmark._deferred_first_scan.promise()

app.bookmark.url_to_bookmark = (url) ->
  original_url = url
  url = app.url.fix(url)
  guess_res = app.url.guess_type(url)

  bookmark =
    type: guess_res.type
    bbs_type: guess_res.bbs_type
    url: url
    title: url
    res_count: null

  arg = app.url.parse_hashquery(original_url)
  if /^\d+$/.test(arg.res_count)
    bookmark.res_count = +arg.res_count
  else
    bookmark.res_count = null

  if /^\d+$/.test(arg.received) and /^\d+$/.test(arg.read) and
      /^\d+$/.test(arg.last)
    bookmark.read_state =
      url: url
      received: +arg.received
      read: +arg.read
      last: +arg.last
  else
    bookmark.read_state = null

  if arg.expired is true
    bookmark.expired = true
  else
    bookmark.expired = false

  bookmark

app.bookmark.bookmark_to_url = (bookmark) ->
  data = {}

  if bookmark.res_count?
    data.res_count = bookmark.res_count

  if bookmark.read_state?
    data.received = bookmark.read_state.received
    data.read = bookmark.read_state.read
    data.last = bookmark.read_state.last

  if bookmark.expired is true
    data.expired = true

  param = app.url.build_param(data)
  bookmark.url + if param then "##{param}" else ""

app.config.ready ->
  source_id = app.config.get("bookmark_id")

  cache = {
    #キーはChromeのブックマークID
    data: {}
    #key: url, value: bookmark_id
    index_url: {}
    #key: board url, value: array of bookmark_id
    index_board_url: {}
  }

  cache.empty = ->
    for id of @data
      cache.remove_bookmark({id})

  cache.get_id = (prop) ->
    if prop.id?
      key = prop.id
    else if prop.url?
      key = @index_url[app.url.fix(prop.url)]
    else
      return null

  cache.get_bookmark = (prop) ->
    app.deep_copy(@data[@get_id(prop)] or null)

  cache.get_bookmark_by_board = (board_url) ->
    board_url = app.url.fix(board_url)
    tmp = []
    for key in @index_board_url[board_url] or []
      tmp.push(@get_bookmark(id: key))
    app.deep_copy(tmp)

  cache.get_all = ->
    app.deep_copy(bookmark for key, bookmark of @data)

  cache.add_bookmark = (tree) ->
    if @data[tree.id]?
      return
    tree = app.deep_copy(tree)
    url = app.url.fix(tree.url)

    bookmark = app.bookmark.url_to_bookmark(tree.url)
    bookmark.title = tree.title

    @data[tree.id] = bookmark
    @index_url[url] = tree.id
    if bookmark.type is "thread"
      board_url = app.url.thread_to_board(url)
      @index_board_url[board_url] or= []
      unless tree.id in @index_board_url[board_url]
        @index_board_url[board_url].push(tree.id)

    app.message.send("bookmark_updated", {type: "added", bookmark})

  cache.update_bookmark = (prop) ->
    if prop.tree?
      cached = @data[prop.tree.id]
      new_url = prop.tree.url
      new_title = prop.tree.title
    else if prop.bookmark?
      cached = @data[cache.get_id(url: prop.bookmark.url)]
      new_url = app.bookmark.bookmark_to_url(prop.bookmark)
      new_title = prop.bookmark.title
    else if prop.id? and prop.url? and prop.title?
      cached = @data[prop.id]
      new_url = prop.url
      new_title = prop.title

    return unless app.url.guess_type(new_url).type in ["board", "thread"]

    #bookmarkが渡された場合に新規登録が必要になることは無いので、
    #treeが渡された場合のみcache.add_bookmarkに派生する
    if not cached and prop.tree?
      #既に同一URLのブックマークが存在する場合は無視する
      if not app.bookmark.get(new_url)
        cache.add_bookmark(prop.tree)
      return

    #同一IDのノードでfixed_urlが変わった場合の対応
    if cached? and (app.url.fix(new_url) isnt cached.url)
      cache.remove_bookmark(id: prop.id)
      cache.add_bookmark(prop)

    new_bookmark = app.bookmark.url_to_bookmark(new_url)
    new_bookmark.title = new_title

    #read_state更新
    do ->
      update_flg = false
      if (not cached.read_state?) and new_bookmark.read_state?
        update_flg = true
      else if cached.read_state? and new_bookmark.read_state?
        if cached.read_state.last isnt new_bookmark.read_state.last or
            cached.read_state.read isnt new_bookmark.read_state.read or
            cached.read_state.received isnt new_bookmark.read_state.received
          update_flg = true

      if update_flg
        cached.read_state = new_bookmark.read_state
        board_url = app.url.thread_to_board(cached.read_state.url)
        app.message.send("read_state_updated",
          {board_url, read_state: cached.read_state})

    #res_count更新
    if cached.res_count isnt new_bookmark.res_count
      cached.res_count = new_bookmark.res_count
      app.message.send("bookmark_updated",
        {type: "res_count", bookmark: cached})

    #expired更新
    if cached.expired isnt new_bookmark.expired
      cached.expired = new_bookmark.expired
      app.message.send("bookmark_updated",
        {type: "expired", bookmark: cached})

    #title更新
    if cached.title isnt new_bookmark.title
      cached.title = new_bookmark.title
      app.message.send("bookmark_updated",
        {type: "title", bookmark: cached})

  cache.remove_bookmark = (prop) ->
    id = @get_id(prop)
    bookmark = @get_bookmark({id})
    if bookmark
      delete @data[id]
      delete @index_url[bookmark.url]
      if bookmark.type is "thread"
        board_url = app.url.thread_to_board(bookmark.url)
        tmp = @index_board_url[board_url].indexOf(id)
        @index_board_url[board_url].splice(tmp, 1)
      app.message.send("bookmark_updated", {type: "removed", bookmark})

  on_bookmark_api_error = ->
    cache.empty()
    app.message.send("open", url: "bookmark_source_selector")
    app.message.send("notify", message: "ブックマークAPIへのアクセスに失敗しました。ブックマークフォルダを再設定して下さい。")

  cache.full_scan = ->
    $.Deferred (deferred) ->
      (deferred.reject(); return) unless source_id?
      chrome.bookmarks.getChildren source_id, (array_of_tree) ->
        if array_of_tree?
          cache.empty()
          for tree in array_of_tree
            if tree.url
              cache.update_bookmark({tree})
          deferred.resolve()
        else
          app.log("warn", "ブックマークスキャン失敗")
          on_bookmark_api_error()
          deferred.reject()
    .promise()

  cache.full_scan()
    .done ->
      if app.bookmark._deferred_first_scan.state() is "pending"
        app.bookmark._deferred_first_scan.resolve()
      return
    .fail ->
      if app.bookmark._deferred_first_scan.state() is "pending"
        app.bookmark._deferred_first_scan.reject()
      return

  # read.crxが実際にブックマークの取得/操作等を行うための関数群

  # ##app.bookmark.get
  # 与えられたURLがブックマークされていた場合はbookmarkオブジェクトを  
  # そうでなかった場合はnullを返す
  app.bookmark.get = (url) ->
    cache.get_bookmark({url})

  # ##app.bookmark.get_all
  # 全てのbookmarkを格納した配列を返す
  app.bookmark.get_all = ->
    cache.get_all()

  app.bookmark.get_by_board = (board_url) ->
    cache.get_bookmark_by_board(board_url)

  app.bookmark.change_source = (new_source_id) ->
    if app.assert_arg("app.bookmark.change_source", ["string"], arguments)
      return

    app.config.set("bookmark_id", new_source_id)
    source_id = new_source_id
    cache.full_scan()

  #res_countはオプショナル
  app.bookmark.add = (url, title, res_count) ->
    deferred = $.Deferred()
    promise = deferred.promise()

    if app.assert_arg("app.bookmark.add", ["string", "string"], arguments)
      deferred.reject()
    else if not cache.get_bookmark({url})?
      app.read_state.get(app.url.fix(url)).always (read_state) ->
        bookmark = app.bookmark.url_to_bookmark(url)
        if read_state
          bookmark.read_state = read_state
        if res_count?
          bookmark.res_count = res_count
        else if read_state?.received?
          bookmark.res_count = read_state.received
        url = app.bookmark.bookmark_to_url(bookmark)
        chrome.bookmarks.create {parentId: source_id, url, title}, (tree) ->
          if tree?
            cache.update_bookmark({tree})
            deferred.resolve()
          else
            app.log("warn", "ブックマーク追加失敗")
            on_bookmark_api_error()
            deferred.reject()
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
      id = cache.get_id({url})
      if typeof id is "string"
        cache.remove_bookmark({id})
        #TODO 失敗時の処理
        chrome.bookmarks.remove id, ->
          deferred.resolve()
      else
        app.log("error", "app.bookmark.remove: ブックマークされていないURLをブックマークから削除しようとしています", arguments)
        deferred.reject()
    return promise

  app.bookmark.remove_by_id = (id) ->
    app.bookmark.remove(cache.get_bookmark({id}).url)

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

        bookmark.read_state or= {}
        bookmark.read_state.received =  read_state.received
        bookmark.read_state.read = read_state.read
        bookmark.read_state.last =  read_state.last
        cache.update_bookmark({bookmark})

        chrome.bookmarks.update(
          cache.get_id({url}),
          url: app.bookmark.bookmark_to_url(bookmark),
          (tree) ->
            if tree?
              deferred.resolve()
            else
              app.log("warn", "ブックマーク更新失敗(read_state)")
              on_bookmark_api_error()
              deferred.reject()
        )
      else
        deferred.reject()
    .promise()

  app.bookmark.update_res_count = (url, res_count) ->
    if bookmark = app.bookmark.get(url)
      if bookmark.res_count is res_count then return

      bookmark.res_count = res_count
      cache.update_bookmark({bookmark})

      chrome.bookmarks.update(
        cache.get_id({url}),
        url: app.bookmark.bookmark_to_url(bookmark),
        (tree) ->
          unless tree?
            app.log("warn", "ブックマーク更新失敗(res_count)")
            on_bookmark_api_error()
      )

  app.bookmark.update_expired = (url, expired) ->
    if bookmark = app.bookmark.get(url)
      if bookmark.expired is expired then return

      bookmark.expired = (expired is true)
      cache.update_bookmark({bookmark})

      chrome.bookmarks.update(
        cache.get_id({url}),
        url: app.bookmark.bookmark_to_url(bookmark),
        (tree) ->
          unless tree?
            app.log("warn", "ブックマーク更新失敗(expired)")
            on_bookmark_api_error()
      )

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
      tmp_url = app.bookmark.bookmark_to_url(bookmark)
      tmp_url = tmp_url.replace(
        ///^(http://)\w+(\.2ch\.net/) ///,
        ($0, $1, $2) -> $1 + tmp + $2
      )
      app.bookmark.add(tmp_url, bookmark.title)
    return

  #Chromeのブックマークの変更を検出してキャッシュを更新する処理群
  do ->
    watcher_wakeflg = true

    chrome.bookmarks.onImportBegan.addListener ->
      watcher_wakeflg = false
      return

    chrome.bookmarks.onImportEnded.addListener ->
      watcher_wakeflg = true
      cache.full_scan()
      return

    chrome.bookmarks.onCreated.addListener (id, tree) ->
      return unless watcher_wakeflg

      if tree.parentId is source_id and tree.url?
        cache.update_bookmark({tree})
      return

    chrome.bookmarks.onRemoved.addListener (id) ->
      return unless watcher_wakeflg

      cache.remove_bookmark({id})
      return

    chrome.bookmarks.onChanged.addListener (id, info) ->
      return unless watcher_wakeflg

      if cache.get_bookmark({id})
        cache.update_bookmark({id, url: info.url, title: info.title})
      return

    chrome.bookmarks.onMoved.addListener (id, e) ->
      return unless watcher_wakeflg

      if e.parentId is source_id
        chrome.bookmarks.get id, (array_of_tree) ->
          if array_of_tree.length is 1 and array_of_tree[0].url?
            cache.update_bookmark(tree: array_of_tree[0])
      else if e.oldParentId is source_id
        cache.remove_bookmark({id})
      return
