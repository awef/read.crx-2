app.view_thread = {}

app.view_thread.open = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()
  $view = $("#template > .view_thread").clone()
  $view.attr("data-url", url)
  $view.attr("data-title", url)
  $view.addClass("loading")

  app.view_module.bookmark_button($view)
  app.view_module.link_button($view)
  app.view_module.reload_button($view)

  $("<a>", {
    href: app.safe_href(app.url.thread_to_board(url))
    class: "open_in_rcrx"
  }).appendTo($view.find(".button_board"))

  write = (param) ->
    param or= {}
    param.url = url
    param.title = $view.attr("data-title")
    open(
      "/write/write.html?#{app.url.build_param(param)}"
      undefined
      'width=600,height=300'
    )

  tsld = app.url.tsld(url)
  if tsld is "2ch.net" or tsld is "livedoor.jp"
    $view.find(".button_write").bind "click", ->
      write()
  else
    $view.find(".button_write").remove()

  #リロードボタンを一時的に無効化する
  suspend_reload_button = ->
    $button = $view.find(".button_reload")
    $button.addClass("disabled")
    setTimeout ->
      $button.removeClass("disabled")
    , 1000 * 5

  #リロード処理
  $view.bind "request_reload", (e, ex) ->
    #read_state保存処理を先に行わせるため、処理を飛ばす
    app.defer ->
      if $view.hasClass("loading")
        return

      $view
        .addClass("loading")
        .find(".content")
          .empty()
          .triggerHandler("lazy_img_destroy")
      app.view_thread._draw($view, ex?.force_update)
        .done ->
          $view.find(".content").lazy_img()
          suspend_reload_button()
        .fail ->
          $view.removeClass("loading")

  app.view_thread._read_state_manager($view)
  app.view_thread._draw($view)
    .fail ->
      $view.removeClass("loading")
    .always ->
      app.history.add(url, $view.attr("data-title"), opened_at)
      $view.find(".content").lazy_img()
      suspend_reload_button()

  $view
    .bind "view_unload", ->
      $view.find(".content").triggerHandler("lazy_img_destroy")

    #名前欄が数字だった場合のポップアップ
    .delegate ".name", "mouseenter", ->
      if /^\d+$/.test(this.textContent)
        if not this.classList.contains("name_num")
          this.classList.add("name_num")

    .delegate ".name_num", "click", (e) ->
      res = $view.find(".content")[0].children[+this.textContent - 1]
      if res
        $popup = $("<div>").append(res.cloneNode(true))
        $.popup($view, $popup, e.clientX, e.clientY, this)

    #コンテキストメニュー 表示
    .delegate ".num", "click contextmenu", (e) ->
      if e.type is "contextmenu"
        e.preventDefault()

      app.defer =>
        $menu = $("#template > .view_thread_resmenu").clone()
        $menu.data("contextmenu_source", this)

        tsld = app.url.tsld(url)
        unless tsld is "2ch.net" or tsld is "livedoor.jp"
          $menu.find(".res_to_this, .res_to_this2").remove()

        $menu.appendTo($view)
        $.contextmenu($menu, e.clientX, e.clientY)

    #コンテキストメニュー 項目クリック
    .delegate ".view_thread_resmenu > *", "click", ->
      $this = $(this)
      $res = $($this.parent().data("contextmenu_source"))
        .closest("article")

      if $this.hasClass("res_to_this")
        write(message: ">>#{$res.find(".num").text()}\n")

      else if $this.hasClass("res_to_this2")
        write(message: """
        >>#{$res.find(".num").text()}
        #{$res.find(".message")[0].innerText.replace(/^/gm, '>')}\n
        """)

      else if $this.hasClass("toggle_aa_mode")
        $res.toggleClass("aa")

      else if $this.hasClass("res_permalink")
        open(url + $res.find(".num").text())

      $this.parent().remove()

    #アンカーポップアップ
    .delegate ".anchor:not(.disabled)", "mouseenter", (e) ->
      tmp = $view.find(".content")[0].children

      frag = document.createDocumentFragment()
      for anchor in app.util.parse_anchor(this.textContent).data
        for segment in anchor.segments
          now = segment[0] - 1
          end = segment[1] - 1
          while now <= end
            if tmp[now]
              frag.appendChild(tmp[now].cloneNode(true))
            else
              break
            now++

      $popup = $("<div>").append(frag)
      $.popup($view, $popup, e.clientX, e.clientY, this)

    #アンカーリンク
    .delegate ".anchor:not(.disabled)", "click", ->
      tmp = app.util.parse_anchor(this.textContent)
      target_res_num = tmp.data[0]?.segments[0]?[0]
      if target_res_num?
        app.view_thread._jump_to_res($view, target_res_num, true)

    #通常リンク
    .delegate ".message a:not(.anchor)", "click", (e) ->
      url = this.href

      #http、httpsスキーム以外ならクリックを無効化する
      if not /// ^https?:// ///.test(url)
        e.preventDefault()
        return

      #read.crxで開けるURLかどうかを判定
      flg = false
      tmp = app.url.guess_type(url)
      #スレのURLはほぼ確実に判定できるので、そのままok
      if tmp.type is "thread"
        flg = true
      #2chタイプ以外の板urlもほぼ確実に判定できる
      else if tmp.type is "board" and tmp.bbs_type isnt "2ch"
        flg = true
      #2chタイプの板は誤爆率が高いので、もう少し細かく判定する
      else if tmp.type is "board" and tmp.bbs_type is "2ch"
        #2ch自体の場合の判断はguess_typeを信じて板判定
        if app.url.tsld(url) is "2ch.net"
          flg = true
        #ブックマークされている場合も板として判定
        else if app.bookmark.get(app.url.fix(url))
          flg = true
      #read.crxで開ける板だった場合はpreventDefaultしてopenメッセージを送出
      if flg
        e.preventDefault()
        app.message.send("open", {url})

    #IDポップアップ
    .delegate ".id.link, .id.freq", "click", (e) ->
      $container = $("<div>")
      $container.append(
        $view
          .find(".id:contains(\"#{this.textContent}\")")
            .closest("article")
              .clone()
      )
      $.popup($view, $container, e.clientX, e.clientY, this)

    #リプライポップアップ
    .delegate ".rep", "click", (e) ->
      tmp = $view.find(".content")[0].children

      frag = document.createDocumentFragment()
      for num in JSON.parse(this.getAttribute("data-replist"))
        frag.appendChild(tmp[num].cloneNode(true))

      $popup = $("<div>").append(frag)
      $.popup($view, $popup, e.clientX, e.clientY, this)

  #クイックジャンプパネル
  _jump_hoge =
    jump_one: "article:nth-child(1)"
    jump_newest: "article:last-child"
    jump_not_read: "article.read + article"
    jump_new: "article.received + article"
    jump_last: "article.last"

  $view.bind "read_state_attached", ->
    already = {}
    for key, val of _jump_hoge
      $tmp = $view.find(val)
      if $tmp.length is 1 and not already[$tmp.index()]?
        $view.find(".#{key}").show()
        already[$tmp.index()] = true
      else
        $view.find(".#{key}").hide()
    null

  $view.find(".jump_panel").bind "click", (e) ->
    $target = $(e.target)

    for key, val of _jump_hoge
      if $target.hasClass(key)
        selector = val
        break

    if selector
      res_num = $view.find(selector).index() + 1

      if typeof res_num is "number"
        app.view_thread._jump_to_res($view, res_num, true)
      else
        app.log("warn", "[view_thread] .jump_panel: ターゲットが存在しません")

  #検索ボックス
  search_stored_scrollTop = null
  $view
    .find(".searchbox")
      .bind "input", ->
        if this.value isnt ""
          if typeof search_stored_scrollTop isnt "number"
            search_stored_scrollTop = $view.find(".content").scrollTop()

          query = this.value.toLowerCase()

          $view
            .find(".content")
              .addClass("searching")
              .children()
              .each ->
                if this.textContent.toLowerCase().indexOf(query) isnt -1
                  this.classList.add("search_hit")
                else
                  this.classList.remove("search_hit")
                null
        else
          $view
            .find(".content")
              .removeClass("searching")
              .find(".search_hit")
                .removeClass("search_hit")

          if typeof search_stored_scrollTop is "number"
            $view.find(".content").scrollTop(search_stored_scrollTop)
            search_stored_scrollTop = null

      .bind "keyup", (e) ->
        if e.which is 27 #Esc
          if this.value isnt ""
            this.value = ""
            $(this).triggerHandler("input")

  #フッター表示処理
  (->
    is_visible = false
    $view.find(".content")
      .bind "scroll", ->
        scroll_left = this.scrollHeight -
            (this.offsetHeight + this.scrollTop)

        if not is_visible and scroll_left is 0
          #表示するべき未読ブックマークが有るかをスキャン
          next = null
          for bookmark in app.bookmark.get_all()
            if bookmark.url is url
              continue
            else if bookmark.read_state? and bookmark.res_count?
              if bookmark.res_count - bookmark.read_state.read > 0
                #TODO もっと綺麗に
                if document.querySelector("[data-url=\"#{bookmark.url}\"]")
                  continue
                else
                  next = bookmark
                  break

          if next
            $view
              .find(".next_unread")
                .attr("href", app.safe_href(next.url))
                .text("未読ブックマーク: #{next.title} (未読#{next.res_count - next.read_state.read}件)")
          else
            $view.find(".next_unread").hide()

          is_visible = true
          $view.find("footer").show()

        else if is_visible and scroll_left isnt 0
          is_visible = false
          $view.find("footer").hide()
  )()

  $view.find(".next_unread").bind "click", ->
    $view.trigger("view_request_killme")

  $view

app.view_thread._jump_to_res = (view, res_num, animate_flg) ->
  $content = $(view).find(".content")
  $target = $content.children(":nth-child(#{res_num}):visible")
  if $target.length > 0
    if animate_flg
      $content.animate(scrollTop: $target[0].offsetTop)
    else
      $content.scrollTop($target[0].offsetTop)

app.view_thread._draw = ($view, force_update) ->
  url = $view.attr("data-url")
  deferred = $.Deferred()

  app.thread.get url, (result) ->
    $message_bar = $view.find(".message_bar")
    if result.status is "error"
      $message_bar.addClass("error").html(result.message)

    if result.data?
      thread = result.data
      $view.attr("data-title", thread.title)
      $view.trigger("title_updated")

      $view.find(".content").append(app.view_thread._draw_messages(thread))
      $view.triggerHandler("draw_content")

      deferred.resolve()
    else
      deferred.reject()

  , force_update
  deferred

app.view_thread._draw_messages = (thread) ->
  #idをキーにレスを取得出来るインデックスを作成
  id_index = {}
  for res, res_key in thread.res
    tmp = /(?:^| )(ID:(?!\?\?\?)[^ ]+)/.exec(res.other)
    if tmp
      id_index[tmp[1]] or= []
      id_index[tmp[1]].push(res_key)
      #>>1のIDを保存しておく
      if res_key is 0
        one_id = tmp[1]

  #参照インデックス構築
  rep_index = {}
  for res, res_key in thread.res
    for anchor in app.util.parse_anchor(res.message).data
      if anchor.target < 25
        for segment in anchor.segments
          i = Math.max(1, segment[0])
          while i <= Math.min(thread.res.length, segment[1])
            rep_index[i] or= []
            rep_index[i].push(res_key)
            i++

  #設定値キャッシュ
  config_thumbnail_supported = app.config.get("thumbnail_supported") is "on"
  config_thumbnail_ext = app.config.get("thumbnail_ext") is "on"

  #サムネイル追加処理
  fn_add_thumbnail = (source_a, thumb_path) ->
    thumb = document.createElement("a")
    thumb.className = "thumbnail"
    thumb.href = app.safe_href(source_a.href)
    thumb.target = "_blank"
    thumb.rel = "noreferrer"

    thumb_img = document.createElement("img")
    thumb_img.src = "/img/dummy_1x1.png"
    thumb_img.setAttribute("data-lazy_img_original_path", thumb_path)
    thumb.appendChild(thumb_img)

    sib = source_a
    while true
      pre = sib
      sib = pre.nextSibling
      if sib is null or sib.nodeName is "BR"
        if sib?.nextSibling?.classList?.contains("thumbnail")
          continue
        if not pre.classList?.contains("thumbnail")
          source_a.parentNode.insertBefore(document.createElement("br"), sib)
        source_a.parentNode.insertBefore(thumb, sib)
        break
    null

  #DOM構築
  frag = document.createDocumentFragment()
  for res, res_key in thread.res
    article = document.createElement("article")
    if /\　\ (?!<br>|$)/i.test(res.message)
      article.className = "aa"

    header = document.createElement("header")
    article.appendChild(header)

    num = document.createElement("span")
    num.className = "num"
    num.textContent = res_key + 1
    header.appendChild(num)

    name = document.createElement("span")
    name.className = "name"
    name.innerHTML = res.name
      .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, "&lt;")
      .replace(/<\/b>(.*?)<b>/g, '<span class="ob">$1</span>')
    header.appendChild(name)

    mail = document.createElement("span")
    mail.className = "mail"
    mail.textContent = res.mail
    header.appendChild(mail)

    other = document.createElement("span")
    other.className = "other"
    other.textContent = res.other

    #.other内のid表示を.idに分離
    tmp = /(^| )(ID:(?!\?\?\?)[^ ]+)/.exec(res.other)
    if tmp
      id_count = id_index[tmp[2]].length

      elm_id = document.createElement("span")

      elm_id.className = "id"
      if id_count >= 5
        elm_id.className += " freq"
      else if id_count >= 2
        elm_id.className += " link"

      elm_id.textContent = "#{tmp[2]} (#{id_count})"

      range = document.createRange()
      range.setStart(other.firstChild, tmp.index + tmp[1].length)
      range.setEnd(other.firstChild, tmp.index + tmp[1].length + tmp[2].length)
      range.deleteContents()
      range.insertNode(elm_id)
      range.detach()

      #>>1と同じIDだった場合、articleにoneクラスを付ける
      if one_id and one_id is tmp[2]
        article.classList.add("one")

    #リプライ数表示追加
    if rep_index[res_key + 1]
      rep_count = rep_index[res_key + 1].length
      rep = document.createElement("span")
      rep.className = "rep #{if rep_count >= 5 then " freq" else " link"}"
      rep.textContent = "返信 (#{rep_count})"
      rep.setAttribute("data-replist", JSON.stringify(rep_index[res_key + 1]))
      other.appendChild(rep)

    header.appendChild(other)

    message = document.createElement("div")
    message.className = "message"
    message.innerHTML = res.message
      #タグ除去
      .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/g, "")
      #URLリンク
      .replace(/(h)?(ttps?:\/\/[\w\-.!~*'();/?:@&=+$,%#]+)/g,
        '<a href="h$2" target="_blank" rel="noreferrer">$1$2</a>')
      #Beアイコン埋め込み表示
      .replace(///^\s*sssp://(img\.2ch\.net/ico/[\w\-_]+\.gif)\s*<br>///,
        '<img class="beicon" src="http://$1" /><br />')
      #アンカーリンク
      .replace /(?:&gt;|＞){1,2}[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?(?:\s*,\s*[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?)*/g, ($0) ->
        str = $0.replace /[\uff10-\uff19]/g, ($0) ->
          String.fromCharCode($0.charCodeAt(0) - 65248)

        reg = /(\d+)(?:-(\d+))?/g
        target_max = 25
        target_count = 0
        while ((res = reg.exec(str)) and target_count <= target_max)
          if res[2]
            if +res[2] > +res[1]
              target_count += +res[2] - +res[1]
          else
            target_count++

        disabled = target_count >= target_max

        "<a href=\"javascript:undefined;\" class=\"anchor" +
        "#{if disabled then " disabled" else ""}\">#{$0}</a>"

    #サムネイル表示(対応サイト)
    if config_thumbnail_supported
      for a in Array::slice.apply(message.getElementsByTagName("a"))
        #YouTube
        if res = /// ^http://
            (?:www\.youtube\.com/watch\?v=|youtu\.be/)
            ([\w\-]+).*
          ///.exec(a.href)
          fn_add_thumbnail(a, "http://img.youtube.com/vi/#{res[1]}/default.jpg")
        #ニコニコ動画
        else if res = /// ^http://(?:www\.nicovideo\.jp/watch/|nico\.ms/)
            (?:sm|nm)(\d+) ///.exec(a.href)
          tmp = "http://tn-skr#{parseInt(res[1], 10) % 4 + 1}.smilevideo.jp"
          tmp += "/smile?i=#{res[1]}"
          fn_add_thumbnail(a, tmp)

    #サムネイル表示(画像っぽいURL)
    if config_thumbnail_ext
      for a in Array::slice.apply(message.getElementsByTagName("a"))
        if /\.(?:png|jpg|jpeg|gif|bmp)$/i.test(a.href)
          fn_add_thumbnail(a, a.href)

    article.appendChild(message)

    frag.appendChild(article)
  frag

app.view_thread._read_state_manager = ($view) ->
  url = $view.attr("data-url")

  read_state = null
  read_state_updated = false

  #read_stateの取得
  promise_get_read_state = $.Deferred (deferred) ->
    if (bookmark = app.bookmark.get(url)) and bookmark.read_state?
      read_state = bookmark.read_state
      deferred.resolve()
    else
      app.read_state.get(url)
        .always (_read_state) ->
          read_state = _read_state or {received: 0, read: 0, last: 0, url}
          deferred.resolve()
  .promise()

  #スレが描画される度に、read_state関連のクラスを付与する
  $view.bind "draw_content", ->
    promise_get_read_state.done ->
      content = $view.find(".content")[0]

      read_state.received = content.children.length
      read_state_updated = true

      content.children[read_state.last - 1]?.classList.add("last")
      content.children[read_state.read - 1]?.classList.add("read")
      content.children[read_state.received - 1]?.classList.add("received")

      $view.triggerHandler("read_state_attached")

      $view.removeClass("loading")
      app.view_thread._jump_to_res($view, read_state.last, false)

  promise_get_read_state.done ->
    scan = ->
      last = read_state.received
      content = $view[0].querySelector(".content")
      bottom = content.scrollTop + content.clientHeight

      for res, res_num in content.children
        if res.offsetTop > bottom
          last = res_num - 1
          break

      if read_state.last isnt last
        read_state.last = last
        read_state_updated = true

      if read_state.read < read_state.last
        read_state.read = read_state.last
        read_state_updated = true

    #アンロード時は非同期系の処理をzombie.htmlに渡す
    #そのためにlocalStorageに更新するread_stateの情報を渡す
    on_beforeunload = ->
      scan()
      if read_state_updated
        if localStorage.zombie_read_state?
          data = JSON.parse(localStorege["zombie_read_state"])
        else
          data = []
        data.push(read_state)
        localStorage["zombie_read_state"] = JSON.stringify(data)
      return

    window.addEventListener("beforeunload", on_beforeunload)

    #read_state.readの値を更新するため、スクロールされたら定期的にスキャンを実行する
    scroll_watcher_suspend = false
    scroll_flg = false
    scroll_watcher = setInterval ->
      if scroll_flg and not scroll_watcher_suspend
        scroll_flg = false
        scan()
    , 250

    $view
      .find(".content")
        .bind "scroll", ->
          scroll_flg = true
      .end()

      .bind "request_reload", ->
        scan()
        if read_state_updated
          app.read_state.set(read_state)
          read_state_updated = false
        scan_watcher_suspend = true

      .bind "draw_content", ->
        scan_watcher_suspend = false

      .bind "view_unload", ->
        window.removeEventListener("beforeunload", on_beforeunload)
        scan()
        if read_state_updated
          app.read_state.set(read_state)
          read_state_updated = false
