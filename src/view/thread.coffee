app.view_thread = {}

app.boot "/view/thread.html", ->
  view_url = app.url.parse_query(location.href).q
  return alert("不正な引数です") unless view_url
  view_url = app.url.fix(view_url)

  document.title = view_url

  $view = $(document.documentElement)
  $view.attr("data-url", view_url)
  $view.addClass("loading")

  $view.data("id_index", {})
  $view.data("rep_index", {})

  app.view_module.view($view)
  app.view_module.bookmark_button($view)
  app.view_module.link_button($view)

  $("<a>", {
    href: app.safe_href(app.url.thread_to_board(view_url))
    class: "open_in_rcrx"
  }).appendTo($view.find(".button_board"))

  write = (param) ->
    param or= {}
    param.url = view_url
    param.title = document.title
    open(
      "/write/write.html?#{app.url.build_param(param)}"
      undefined
      'width=600,height=300'
    )

  popup_helper = (that, e, fn) ->
    $popup = fn()
    return if $popup.children().length is 0
    $popup.find("article").removeClass("last read received")
    #ポップアップ内のサムネイルの遅延ロードを解除
    $popup.find("img[data-href]").each ->
      @src = @getAttribute("data-href")
      @removeAttribute("data-href")
      return
    $.popup($view, $popup, e.clientX, e.clientY, that)

  if app.url.tsld(view_url) in ["2ch.net", "livedoor.jp"]
    $view.find(".button_write").bind "click", ->
      write()
      return
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
    return if $view.hasClass("loading")

    tmp_scrollTop = $view.find(".content").scrollTop()

    $view
      .addClass("loading")
      .find(".content")
        .removeClass("searching")
        .removeAttr("data-res_search_hit_count")
      .end()
      .find(".searchbox")
        .val("")

    app.view_thread._draw($view, ex?.force_update)
      .done ->
        suspend_reload_button()
      .always ->
        $view.removeClass("loading")
        $view.find(".content").scrollTop(tmp_scrollTop)

    return

  #初回ロード処理
  (->
    opened_at = Date.now()

    app.view_thread._read_state_manager($view)
    $view.one "read_state_attached", ->
      on_scroll = false
      $view.find(".content").one "scroll", ->
        on_scroll = true

      $view.removeClass("loading")

      $last = $view.find(".content > .last")
      if $last.length is 1
        app.view_thread._jump_to_res($view, +$last.find(".num").text(), false)

      #スクロールされなかった場合も余所の処理を走らすためにscrollを発火
      unless on_scroll
        $view.find(".content").triggerHandler("scroll")

    app.view_thread._draw($view)
      .fail ->
         $view.removeClass("loading")
      .always ->
        app.history.add(view_url, document.title, opened_at)
        suspend_reload_button()
  )()

  $view
    #名前欄が数字だった場合のポップアップ
    .delegate ".name", "mouseenter", ->
      if /^\d+$/.test(this.textContent)
        if not this.classList.contains("name_num")
          this.classList.add("name_num")
      return

    .delegate ".name_num", "click", (e) ->
      popup_helper this, e, =>
        res = $view.find(".content")[0].children[+this.textContent - 1]
        $("<div>").append($(res).clone())
      return

    #コンテキストメニュー 表示
    .delegate ".num", "click contextmenu", (e) ->
      if e.type is "contextmenu"
        e.preventDefault()

      app.defer =>
        $menu = $("#template > .view_thread_resmenu").clone()
        $menu.data("contextmenu_source", this)

        if not(app.url.tsld(view_url) in ["2ch.net", "livedoor.jp"])
          $menu.find(".res_to_this, .res_to_this2").remove()

        $menu.appendTo($view)
        $.contextmenu($menu, e.clientX, e.clientY).appendTo(@parentNode)

      return

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
        open(view_url + $res.find(".num").text())

      $this.parent().remove()

      return

    #アンカーポップアップ
    .delegate ".anchor", "mouseenter", (e) ->
      popup_helper this, e, =>
        $popup = $("<div>")
        if not @classList.contains("disabled")
          tmp = $view.find(".content")[0].children
          for anchor in app.util.parse_anchor(this.innerHTML).data
            for segment in anchor.segments
              now = segment[0] - 1
              end = segment[1] - 1
              while now <= end
                if tmp[now]
                  $popup.append(tmp[now].cloneNode(true))
                else
                  break
                now++
        else
          $("<div>", {
              text: "指定されたレスの量が極端に多いため、ポップアップを表示しません"
              class: "anchor_popup_disabled_message"
            })
            .appendTo($popup)
        $popup
      return

    #アンカーリンク
    .delegate ".anchor:not(.disabled)", "click", ->
      tmp = app.util.parse_anchor(this.innerHTML)
      target_res_num = tmp.data[0]?.segments[0]?[0]
      if target_res_num?
        app.view_thread._jump_to_res($view, target_res_num, true)
      return

    #通常リンク
    .delegate ".message a:not(.anchor)", "click", (e) ->
      target_url = this.href

      #http、httpsスキーム以外ならクリックを無効化する
      if not /// ^https?:// ///.test(target_url)
        e.preventDefault()
        return

      #read.crxで開けるURLかどうかを判定
      flg = false
      tmp = app.url.guess_type(target_url)
      #スレのURLはほぼ確実に判定できるので、そのままok
      if tmp.type is "thread"
        flg = true
      #2chタイプ以外の板urlもほぼ確実に判定できる
      else if tmp.type is "board" and tmp.bbs_type isnt "2ch"
        flg = true
      #2chタイプの板は誤爆率が高いので、もう少し細かく判定する
      else if tmp.type is "board" and tmp.bbs_type is "2ch"
        #2ch自体の場合の判断はguess_typeを信じて板判定
        if app.url.tsld(target_url) is "2ch.net"
          flg = true
        #ブックマークされている場合も板として判定
        else if app.bookmark.get(app.url.fix(target_url))
          flg = true
      #read.crxで開ける板だった場合はpreventDefaultしてopenメッセージを送出
      if flg
        e.preventDefault()
        app.message.send("open", url: target_url)
      return

    #リンク先情報ポップアップ
    .delegate ".message a:not(.anchor)", "mouseenter", (e) ->
      tmp = app.url.guess_type(@href)
      if tmp.type is "board"
        board_url = app.url.fix(@href)
        after = ""
      else if tmp.type is "thread"
        board_url = app.url.thread_to_board(@href)
        after = "のスレ"
      else
        return

      app.board_title_solver.ask({url: board_url, offline: true})
        .done (title) =>
          popup_helper this, e, =>
            $("<div>")
              .addClass("popup_linkinfo")
              .append($("<div>").text(title + after))
      return

    #IDポップアップ
    .delegate ".id.link, .id.freq, .anchor_id", (app.config.get("popup_trigger") or "click"), (e) ->
      popup_helper @, e, =>
        id_text = @textContent
          .replace(/^id:/i, "ID:")
          .replace(/\(\d+\)$/, "")

        $popup = $("<div>")
        $view
          .find(".id")
            .filter(->
              @textContent[0...id_text.length] is id_text and
                /^\(\d+\)$/.test(@textContent[id_text.length...])
            )
              .closest("article")
                .filter(".content > article")
                  .clone()
                    .appendTo($popup)
        $popup
      return

    #リプライポップアップ
    .delegate ".rep", (app.config.get("popup_trigger") or "click"), (e) ->
      popup_helper this, e, =>
        tmp = $view.find(".content")[0].children

        frag = document.createDocumentFragment()
        res_key = +$(@).closest("article").find(".num").text()
        for num in $view.data("rep_index")[res_key]
          frag.appendChild(tmp[num].cloneNode(true))

        $popup = $("<div>").append(frag)
      return

  #クイックジャンプパネル
  (->
    jump_hoge =
      jump_one: "article:nth-child(1)"
      jump_newest: "article:last-child"
      jump_not_read: "article.read + article"
      jump_new: "article.received + article"
      jump_last: "article.last"

    $view.bind "read_state_attached", ->
      already = {}
      for key, val of jump_hoge
        $tmp = $view.find(val)
        if $tmp.length is 1 and not already[$tmp.index()]?
          $view.find(".#{key}").css("display", "block")
          already[$tmp.index()] = true
        else
          $view.find(".#{key}").css("display", "none")
      return

    $view.find(".jump_panel").bind "click", (e) ->
      $target = $(e.target)

      for key, val of jump_hoge
        if $target.hasClass(key)
          selector = val
          break

      if selector
        res_num = $view.find(selector).index() + 1

        if typeof res_num is "number"
          app.view_thread._jump_to_res($view, res_num, true)
        else
          app.log("warn", "[view_thread] .jump_panel: ターゲットが存在しません")
      return
  )()

  #検索ボックス
  search_stored_scrollTop = null
  $view
    .find(".searchbox")
      .bind "input", ->
        if this.value isnt ""
          if typeof search_stored_scrollTop isnt "number"
            search_stored_scrollTop = $view.find(".content").scrollTop()

          hit_count = 0
          query = this.value.toLowerCase()

          $view
            .find(".content")
              .addClass("searching")
              .children()
              .each ->
                if this.textContent.toLowerCase().indexOf(query) isnt -1
                  this.classList.add("search_hit")
                  hit_count++
                else
                  this.classList.remove("search_hit")
                null
            .end()
            .attr("data-res_search_hit_count", hit_count)
        else
          $view
            .find(".content")
              .removeClass("searching")
              .removeAttr("data-res_search_hit_count")
              .find(".search_hit")
                .removeClass("search_hit")

          if typeof search_stored_scrollTop is "number"
            $view.find(".content").scrollTop(search_stored_scrollTop)
            search_stored_scrollTop = null
        return

      .bind "keyup", (e) ->
        if e.which is 27 #Esc
          if this.value isnt ""
            this.value = ""
            $(this).triggerHandler("input")
        return

  #フッター表示処理
  update_footer = ->
    content = $view[0].querySelector(".content")
    scroll_left = content.scrollHeight -
        (content.offsetHeight + content.scrollTop)

    #未読ブックマーク表示更新
    if scroll_left is 0
      #表示するべき未読ブックマークが有るかをスキャン
      next = null
      for bookmark in app.bookmark.get_all()
        if bookmark.type isnt "thread" or bookmark.url is view_url
          continue

        if bookmark.res_count?
          if bookmark.res_count - (bookmark.read_state?.read or 0) is 0
            continue

        if parent.document.querySelector("[data-url=\"#{bookmark.url}\"]")
          continue
        else
          next = bookmark
          break

      if next
        text = "未読ブックマーク: #{next.title}"
        if next.res_count?
          text += " (未読#{next.res_count - (next.read_state?.read or 0)}件)"
        $view
          .find(".next_unread")
            .attr("href", app.safe_href(next.url))
            .text(text)
            .show()
      else
        $view.find(".next_unread").hide()

    #フッター自体の表示/非表示を更新
    if scroll_left is 0
      $view.find("footer").show()
    else
      $view.find("footer").hide()

  $view
    .bind "tab_selected", ->
      update_footer()
      return

    .find(".content")
      .bind "scroll", ->
        update_footer()
        return

  $view.find(".next_unread").bind "click", ->
    if frameElement
      tmp = {type: "request_killme"}
      parent.postMessage(JSON.stringify(tmp), location.origin)
    return

app.view_thread._jump_to_res = (view, res_num, animate_flg) ->
  $content = $(view).find(".content")
  $target = $content.children(":nth-child(#{res_num})")
  if $target.length > 0
    return if $content.hasClass("searching") and not $target.hasClass("search_hit")
    if animate_flg
      $content.animate(scrollTop: $target[0].offsetTop)
    else
      $content.scrollTop($target[0].offsetTop)

app.view_thread._draw = ($view, force_update) ->
  deferred = $.Deferred()

  app.thread.get $view.attr("data-url"), (result) ->
    $content = $view.find(".content")
    content = $content[0]

    if result.status is "error"
      $view.find(".message_bar").addClass("error").html(result.message)
    else
      $view.find(".message_bar").removeClass("error").empty()

    (deferred.reject(); return) unless result.data?

    thread = result.data
    document.title = thread.title

    #DOM構築
    (->
      completed = content.childNodes.length
      frag = document.createDocumentFragment()
      for res, res_key in thread.res
        continue if res_key < completed
        frag.appendChild(app.view_thread._const_res(res_key, res, $view))
      content.appendChild(frag)
    )()
    #idカウント, .freq/.link更新
    (->
      for id, index of $view.data("id_index")
        for res_key in index
          id_count = index.length
          elm = content.childNodes[res_key].getElementsByClassName("id")[0]

          elm.textContent =
            elm.textContent.replace(/(?:\(\d+\))?$/, "(#{id_count})")

          if id_count >= 5
            elm.classList.remove("link")
            elm.classList.add("freq")
          else if id_count >= 2
            elm.classList.add("link")
          null
        null
    )()
    #.one付与
    (->
      one_id = content.firstChild?.getAttribute("data-id")
      if one_id?
        for id in $view.data("id_index")[one_id]
          content.children[id].classList.add("one")
    )()
    #参照関係再構築
    (->
      for res_key, index of $view.data("rep_index")
        res = content.childNodes[res_key - 1]
        if res
          res_count = index.length
          elm = res.getElementsByClassName("rep")[0]
          unless elm
            elm = document.createElement("span")
            elm.className = "rep"
            res.getElementsByClassName("other")[0].appendChild(elm)
          elm.textContent = "返信 (#{res_count})"

          if res_count >= 5
            elm.classList.remove("link")
            elm.classList.add("freq")
          else
            elm.classList.add("link")
    )()
    #サムネイル追加処理
    (->
      imgs = []
      fn_add_thumbnail = (source_a, thumb_path) ->
        source_a.classList.add("has_thumbnail")

        thumb = document.createElement("a")
        thumb.className = "thumbnail"
        thumb.href = app.safe_href(source_a.href)
        thumb.target = "_blank"
        thumb.rel = "noreferrer"

        thumb_img = document.createElement("img")
        thumb_img.src = "/img/loading.svg"
        thumb_img.setAttribute("data-href", thumb_path)
        thumb.appendChild(thumb_img)

        imgs.push(thumb_img)

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

      config_thumbnail_supported =
        app.config.get("thumbnail_supported") is "on"
      config_thumbnail_ext =
        app.config.get("thumbnail_ext") is "on"

      for a in content.querySelectorAll(".message > a:not(.thumbnail):not(.has_thumbnail)")
        #サムネイル表示(対応サイト)
        if config_thumbnail_supported
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
          if /\.(?:png|jpg|jpeg|gif|bmp)$/i.test(a.href)
            fn_add_thumbnail(a, a.href)

      $(imgs).jail(
        timeout: 20
        effect: "fadeIn"
        selector: ".content"
      )
    )()

    $view.trigger("view_loaded")

    deferred.resolve()

  , force_update

  deferred.promise()

app.view_thread._const_res = (res_key, res, $view) ->
  article = document.createElement("article")
  article.className = "aa" if /(?:\　{5}|\　\ )(?!<br>|$)/i.test(res.message)

  header = document.createElement("header")

  #.num
  num = document.createElement("span")
  num.className = "num"
  num.textContent = res_key + 1
  header.appendChild(num)

  #.name
  name = document.createElement("span")
  name.className = "name"
  name.innerHTML = res.name
    .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, "&lt;")
    .replace(/<\/b>(.*?)<b>/g, '<span class="ob">$1</span>')
  header.appendChild(name)

  #.mail
  mail = document.createElement("span")
  mail.className = "mail"
  #タグ除去
  mail.innerHTML = res.mail.replace(/<.*?(?:>|$)/g, "")
  header.appendChild(mail)

  #.other
  other = document.createElement("span")
  other.className = "other"
  other.innerHTML = res.other
    #タグ除去
    .replace(/<.*?(?:>|$)/g, "")
    #.id
    .replace /(^| )(ID:(?!\?\?\?)[^ <>"']+)/, ($0, $1, $2) ->
      article.setAttribute("data-id", $2)

      id_index = $view.data("id_index")
      id_index[$2] = [] unless id_index[$2]?
      id_index[$2].push(res_key)

      """#{$1}<span class="id">#{$2}</span>"""

  header.appendChild(other)

  article.appendChild(header)

  message = document.createElement("div")
  message.className = "message"
  message.innerHTML = res.message
    #タグ除去
    .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/g, "")
    #URLリンク
    .replace(/(h)?(ttps?:\/\/(?:[a-hj-zA-HJ-Z\d_\-.!~*'();\/?:@=+$,%#]|\&(?!(?:#(\d+)|#x([\dA-Fa-f]+)|([\da-zA-Z]+));)|[iI](?![dD]:)+)+)/g,
      '<a href="h$2" target="_blank" rel="noreferrer">$1$2</a>')
    #Beアイコン埋め込み表示
    .replace(///^\s*sssp://(img\.2ch\.net/ico/[\w\-_]+\.gif)\s*<br>///,
      '<img class="beicon" src="http://$1" /><br />')
    #アンカーリンク
    .replace /(?:&gt;|＞){1,2}[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?(?:\s*,\s*[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?)*/g, ($0) ->
      str = $0.replace /[\uff10-\uff19]/g, ($0) ->
        String.fromCharCode($0.charCodeAt(0) - 65248)

      anchor = app.util.parse_anchor($0)
      disabled = anchor.target >= 25 or anchor.data.length is 0

      #rep_index更新
      if not disabled
        rep_index = $view.data("rep_index")
        #アンカー一つづつしか来ない処理なので、決め打ちで
        for segment in anchor.data[0].segments
          target = Math.max(1, segment[0])
          while target <= segment[1]
            rep_index[target] = [] unless rep_index[target]?
            rep_index[target].push(res_key) unless res_key in rep_index[target]
            target++

      "<a href=\"javascript:undefined;\" class=\"anchor" +
      "#{if disabled then " disabled" else ""}\">#{$0}</a>"
    #IDリンク
    .replace /id:(?:[a-hj-z\d_\+\/\.]|i(?!d:))+/ig, ($0) ->
      "<a href=\"javascript:undefined;\" class=\"anchor_id\">#{$0}</a>"

  article.appendChild(message)

  article

app.view_thread._read_state_manager = ($view) ->
  view_url = $view.attr("data-url")

  read_state = null
  read_state_updated = false

  #read_stateの取得
  promise_get_read_state = $.Deferred (deferred) ->
    if (bookmark = app.bookmark.get(view_url)) and bookmark.read_state?
      read_state = bookmark.read_state
      deferred.resolve()
    else
      app.read_state.get(view_url)
        .always (_read_state) ->
          read_state = _read_state or {received: 0, read: 0, last: 0, url: view_url}
          deferred.resolve()
  .promise()

  #スレの描画時に、read_state関連のクラスを付与する
  $view.bind "view_loaded", ->
    promise_get_read_state.done ->
      $content = $view.find(".content")
      content = $content[0]

      $content
        .find("> .last, > .read, .received")
          .removeClass("last read received")

      content.children[read_state.last - 1]?.classList.add("last")
      content.children[read_state.read - 1]?.classList.add("read")
      content.children[read_state.received - 1]?.classList.add("received")

      $view.triggerHandler("read_state_attached")
    return

  promise_get_read_state.done ->
    scan = ->
      content = $view[0].querySelector(".content")
      bottom = content.scrollTop + content.clientHeight

      received = content.childNodes.length
      if read_state.received isnt received
        read_state.received = received
        read_state_updated = true

      last = read_state.received
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
          data = JSON.parse(localStorage["zombie_read_state"])
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
        if read_state_updated
          app.read_state.set(read_state)
    , 250

    $view
      .find(".content")
        .bind "scroll", ->
          scroll_flg = true
          return
      .end()

      .bind "request_reload", ->
        scroll_watcher_suspend = true
        return

      .bind "view_loaded", ->
        scroll_watcher_suspend = false
        return

      .bind "view_unload", ->
        clearInterval(scroll_watcher)
        window.removeEventListener("beforeunload", on_beforeunload)
        scan()
        if read_state_updated
          app.read_state.set(read_state)
          app.bookmark.update_read_state(read_state)
          read_state_updated = false
        return
