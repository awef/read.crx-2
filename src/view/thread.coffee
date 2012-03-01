app.view_thread = {}

app.boot "/view/thread.html", ->
  view_url = app.url.parse_query(location.href).q
  return alert("不正な引数です") unless view_url
  view_url = app.url.fix(view_url)

  $view = $(document.documentElement)
  $view.attr("data-url", view_url)

  $view.data("id_index", {})
  $view.data("rep_index", {})

  app.view_module.view($view)
  app.view_module.bookmark_button($view)
  app.view_module.tool_menu($view)

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

  #リロード処理
  $view.on "request_reload", (e, ex) ->
    #先にread_state更新処理を走らせるために、処理を飛ばす
    app.defer ->
      return if $view.hasClass("loading")
      return if $view.find(".button_reload").hasClass("disabled")

      $view
        .find(".content")
          .removeClass("searching")
          .removeAttr("data-res_search_hit_count")
        .end()
        .find(".searchbox")
          .val("")

      app.view_thread._draw($view, ex?.force_update)

    return

  #初回ロード処理
  do ->
    opened_at = Date.now()

    app.view_thread._read_state_manager($view)
    $view.one "read_state_attached", ->
      on_scroll = false
      $view.find(".content").one "scroll", ->
        on_scroll = true

      $last = $view.find(".content > .last")
      if $last.length is 1
        app.view_thread._jump_to_res($view, +$last.find(".num").text(), false)

      #スクロールされなかった場合も余所の処理を走らすためにscrollを発火
      unless on_scroll
        $view.find(".content").triggerHandler("scroll")

      #二度目以降のread_state_attached時に、最後に見ていたスレが当時最新のレスだった場合、新着を強調表示するためにスクロールを行う
      $view.on "read_state_attached", ->
        $tmp = $view.find(".content > .last.received + article")
        return if $tmp.length isnt 1
        app.view_thread._jump_to_res($view, +$tmp.find(".num").text(), true, -100)

    app.view_thread._draw($view)
      .always ->
        app.history.add(view_url, document.title, opened_at)

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

    #レスメニュー表示
    .on "click", "article", (e) ->
      return if $(e.target).is("a, .link, .freq, .name_num")
      append_flg = $(@).has(".res_footer").length is 0
      $view
        .find("article > .res_footer")
          .hide(100, (-> $(@).remove(); return))
      if append_flg
        $menu = $view.find("#template > .res_footer").clone()

        unless app.url.tsld(view_url) in ["2ch.net", "livedoor.jp"]
          $menu.find(".res_to_this, .res_to_this2").remove()

        unless $(@).is(".popup > article")
          $menu.find(".jump_to_this").remove()

        $menu
          .hide()
          .appendTo(@)
          .show(100)
      return

    #レスメニュー項目クリック
    .on "click", ".res_footer > span", "click", ->
      $this = $(@)
      $res = $this.closest("article")

      if $this.hasClass("jump_to_this")
        app.view_thread._jump_to_res($view, +$res.find(".num").text(), true)

      else if $this.hasClass("res_to_this")
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
    .delegate ".anchor", "click", (e) ->
      e.preventDefault()
      return if @classList.contains("disabled")

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

      #.open_in_rcrxが付与されている場合、処理は他モジュールに任せる
      return if @classList.contains("open_in_rcrx")

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
      #read.crxで開ける板だった場合は.open_in_rcrxを付与して再度クリックイベント送出
      if flg
        e.preventDefault()
        @classList.add("open_in_rcrx")
        app.defer =>
          $(@).trigger(e)
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
    .delegate ".id.link, .id.freq, .anchor_id", app.config.get("popup_trigger"), (e) ->
      e.preventDefault()

      popup_helper @, e, =>
        id_text = @textContent
          .replace(/^id:/i, "ID:")
          .replace(/\(\d+\)$/, "")
          .replace(/\u25cf$/, "") #末尾●除去

        $popup = $("<div>")
        $view
          .find(".content > article[data-id=\"#{id_text}\"]")
            .clone()
              .appendTo($popup)
        $popup
      return

    #リプライポップアップ
    .delegate ".rep", app.config.get("popup_trigger"), (e) ->
      popup_helper this, e, =>
        tmp = $view.find(".content")[0].children

        frag = document.createDocumentFragment()
        res_key = +$(@).closest("article").find(".num").text()
        for num in $view.data("rep_index")[res_key]
          frag.appendChild(tmp[num].cloneNode(true))

        $popup = $("<div>").append(frag)
      return

  #クイックジャンプパネル
  do ->
    jump_hoge =
      ".jump_one": "article:nth-child(1)"
      ".jump_newest": "article:last-child"
      ".jump_not_read": "article.read + article"
      ".jump_new": "article.received + article"
      ".jump_last": "article.last"

    $jump_panel = $view.find(".jump_panel")

    $view.on "read_state_attached", ->
      already = {}
      for panel_item_selector, target_res_selector of jump_hoge
        res = $view[0].querySelector(target_res_selector)
        res_num = +res.querySelector(".num").textContent if res
        if res and not already[res_num]
          $jump_panel[0]
            .querySelector(panel_item_selector)
              .style["display"] = "block"
          already[res_num] = true
        else
          $jump_panel[0]
            .querySelector(panel_item_selector)
              .style["display"] = "none"
      return

    $jump_panel.on "click", (e) ->
      $target = $(e.target)

      for key, val of jump_hoge
        if $target.is(key)
          selector = val
          break

      if selector
        res_num = $view.find(selector).index() + 1

        if typeof res_num is "number"
          app.view_thread._jump_to_res($view, res_num, true)
        else
          app.log("warn", "[view_thread] .jump_panel: ターゲットが存在しません")
      return
    return

  #検索ボックス
  do ->
    search_stored_scrollTop = null
    $view
      .find(".searchbox")
        .on "input", ->
          if @value isnt ""
            if typeof search_stored_scrollTop isnt "number"
              search_stored_scrollTop = $view.find(".content").scrollTop()

            hit_count = 0
            query = app.util.normalize(@value)

            $view
              .find(".content")
                .addClass("searching")
                .children()
                .each ->
                  if app.util.normalize(@textContent).indexOf(query) isnt -1
                    @classList.add("search_hit")
                    hit_count++
                  else
                    @classList.remove("search_hit")
                  return
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

        .on "keyup", (e) ->
          if e.which is 27 #Esc
            if @value isnt ""
              @value = ""
              $(@).triggerHandler("input")
          return

  #フッター表示処理
  do ->
    content = $view.find(".content")[0]

    scroll_left = 0
    update_scroll_left = ->
      scroll_left = content.scrollHeight - (content.offsetHeight + content.scrollTop)
      return

    #未読ブックマーク数表示
    next_unread =
      _elm: $view.find(".next_unread")[0]
      show: ->
        next = null
        for bookmark in app.bookmark.get_all()
          if bookmark.type isnt "thread" or bookmark.url is view_url
            continue

          if bookmark.res_count?
            if bookmark.res_count - (bookmark.read_state?.read or 0) <= 0
              continue

          #既にタブで開かれている場合は無視
          if parent.document.querySelector("[data-url=\"#{bookmark.url}\"]")
            continue

          next = bookmark
          break

        if next
          text = "未読ブックマーク: #{next.title}"
          if next.res_count?
            text += " (未読#{next.res_count - (next.read_state?.read or 0)}件)"
          @_elm.href = app.safe_href(next.url)
          @_elm.textContent = text
          @_elm.setAttribute("data-title", next.title)
          @_elm.style["display"] = "block"
        else
          @hide()
        return
      hide: ->
        @_elm.style["display"] = "none"
        return

    search_next_thread =
      _elm: $view.find(".search_next_thread")[0]
      show: ->
        if content.childNodes.length >= 1000
          @_elm.style["display"] = "block"
        else
          @hide()
        return
      hide: ->
        @_elm.style["display"] = "none"
        return

    update_thread_footer = ->
      if scroll_left is 0
        next_unread.show()
        search_next_thread.show()
      else
        next_unread.hide()
        search_next_thread.hide()
      return

    $view
      .on "tab_selected view_loaded", ->
        update_thread_footer()
        return

      .find(".content").on "scroll", ->
        update_scroll_left()
        update_thread_footer()
        return
      .end()

      #次スレ検索
      .find(".button_tool_search_next_thread, .search_next_thread").on "click", (e) ->
        if $view.find(".next_thread_list:visible").length isnt 0
          return
        $div = $("#template > .next_thread_list").clone()
        $div.find(".close").one "click", ->
          $div.fadeOut("fast", -> $div.remove)
          return
        $div.find(".current").text(document.title)
        $div.find(".status").text("検索中")
        $div.appendTo(document.body)
        app.util.search_next_thread(view_url, document.title)
          .done (res) ->
            $div.find(".status").text("")
            $ol = $div.find("ol")
            for thread in res
              $("<li>", {
                class: "open_in_rcrx"
                text: thread.title
                "data-href": thread.url
              }).appendTo($ol)
            return
          .fail ->
            $div.find(".status").text("次スレ検索に失敗しました")
            return
        return

    app.message.add_listener "bookmark_updated", (message) ->
      if scroll_left is 0
        next_unread.show()
      return

    return

  #サムネイルロード時の縦位置調整
  $view.on "lazy_load_complete", ".thumbnail > a > img", ->
    a = @parentNode
    container = a.parentNode
    a.style["top"] = "#{(container.offsetHeight - a.offsetHeight) / 2}px"

  #パンくずリスト表示
  do ->
    board_url = app.url.thread_to_board(view_url)
    app.board_title_solver.ask(url: board_url, offline: true)
      .always (title) ->
        $view
          .find(".breadcrumb > li > a")
            .attr("href", board_url)
            .text(if title? then "#{title.replace(/板$/, "")}板" else "板")
        return
    return

  return

app.view_thread._jump_to_res = ($view, res_num, animate_flg, offset = -10) ->
  content = $view[0].querySelector(".content")
  target = content.childNodes[res_num - 1]
  if target
    return if content.classList.contains("searching") and not target.classList.contains("search_hit")
    if animate_flg
      $(content).animate(scrollTop: target.offsetTop + offset)
    else
      content.scrollTop = target.offsetTop + offset

app.view_thread._draw = ($view, force_update) ->
  deferred = $.Deferred()

  $view.addClass("loading")
  $reload_button = $view.find(".button_reload")
  $reload_button.addClass("disabled")
  content = $view.find(".content")[0]
  id_index = $view.data("id_index")
  rep_index = $view.data("rep_index")

  fn = (thread, error) ->
    if error
      $view.find(".message_bar").addClass("error").html(thread.message)
    else
      $view.find(".message_bar").removeClass("error").empty()

    (deferred.reject(); return) unless thread.res?

    document.title = thread.title

    #DOM構築
    do ->
      completed = content.childNodes.length
      tmp = ""
      for res, res_key in thread.res
        continue if res_key < completed
        tmp += app.view_thread._const_res_html(res_key, res, $view, id_index, rep_index)
      content.insertAdjacentHTML("BeforeEnd", tmp)
      return
    #idカウント, .freq/.link更新
    do ->
      for id, index of id_index
        id_count = index.length
        for res_key in index
          elm = content.childNodes[res_key].getElementsByClassName("id")[0]
          elm.firstChild.nodeValue = elm.firstChild.nodeValue.replace(/(?:\(\d+\))?$/, "(#{id_count})")
          if id_count >= 5
            elm.classList.remove("link")
            elm.classList.add("freq")
          else if id_count >= 2
            elm.classList.add("link")
      return
    #.one付与
    do ->
      one_id = content.firstChild?.getAttribute("data-id")
      if one_id?
        for id in id_index[one_id]
          content.children[id].classList.add("one")
    #参照関係再構築
    do ->
      for res_key, index of rep_index
        res = content.childNodes[res_key - 1]
        if res
          res_count = index.length
          if elm = res.getElementsByClassName("rep")[0]
            new_flg = false
          else
            new_flg = true
            elm = document.createElement("span")
          elm.textContent = "返信 (#{res_count})"
          elm.className = if res_count >= 5 then "rep freq" else "rep link"
          if new_flg
            res.getElementsByClassName("other")[0].appendChild(elm)
      return
    #サムネイル追加処理
    do ->
      imgs = []
      fn_add_thumbnail = (source_a, thumb_path) ->
        source_a.classList.add("has_thumbnail")

        thumb = document.createElement("div")
        thumb.className = "thumbnail"

        thumb_link = document.createElement("a")
        thumb_link.href = app.safe_href(source_a.href)
        thumb_link.target = "_blank"
        thumb_link.rel = "noreferrer"
        thumb.appendChild(thumb_link)

        thumb_img = document.createElement("img")
        thumb_img.src = "/img/loading.svg"
        thumb_img.setAttribute("data-href", thumb_path)
        thumb_link.appendChild(thumb_img)

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
          if /\.(?:png|jpe?g|gif|bmp|webp)$/i.test(a.href)
            fn_add_thumbnail(a, a.href)

      $(imgs).lazy_load(container: ".content")

    $view.trigger("view_loaded")

    deferred.resolve()

  app.module null, ["thread"], (Thread) ->
    thread = new Thread($view.attr("data-url"))
    thread.get(force_update)
      .progress ->
        fn(thread, false)
        return
      .done ->
        $view.data("last_updated", Date.now())
        fn(thread, false)
        return
      .fail ->
        fn(thread, true)
        return
      .always ->
        $view.removeClass("loading")
        setTimeout((-> $reload_button.removeClass("disabled")), 1000 * 5)
        return
    return

  deferred.promise()

app.view_thread._const_res_html = (res_key, res, $view, id_index, rep_index) ->
  return null if typeof res_key isnt "number" or isNaN(res_key)

  attribute_data_id = null

  html = "<header>"

  #.num
  html += """<span class="num">#{res_key + 1}</span>"""

  #.name
  tmp = (
    res.name
      .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, "&lt;")
      .replace(/<\/b>(.*?)<b>/g, """<span class="ob">$1</span>""")
  )
  html += """<span class="name">#{tmp}</span>"""

  #.mail
  tmp = res.mail.replace(/<.*?(?:>|$)/g, "")
  html += """<span class="mail">#{tmp}</span>"""

  #.other
  tmp = (
    res.other
      #タグ除去
      .replace(/<.*?(?:>|$)/g, "")
      #.id
      .replace /(^| )(ID:(?!\?\?\?)[^ <>"']+)/, ($0, $1, $2) ->
        fixed_id = $2.replace(/\u25cf$/, "") #末尾●除去

        attribute_data_id = fixed_id

        id_index[fixed_id] = [] unless id_index[fixed_id]?
        id_index[fixed_id].push(res_key)

        """#{$1}<span class="id">#{$2}</span>"""
  )
  html += """<span class="other">#{tmp}</span>"""

  html += "</header>"

  tmp = (
    res.message
      #タグ除去
      .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/ig, "")
      #URLリンク
      .replace(/(h)?(ttps?:\/\/(?:[a-hj-zA-HJ-Z\d_\-.!~*'();\/?:@=+$,%#]|\&(?!(?:#(\d+)|#x([\dA-Fa-f]+)|([\da-zA-Z]+));)|[iI](?![dD]:)+)+)/g,
        '<a href="h$2" target="_blank" rel="noreferrer">$1$2</a>')
      #Beアイコン埋め込み表示
      .replace ///^\s*sssp://(img\.2ch\.net/ico/[\w\-_]+\.gif)\s*<br>///, ($0, $1) ->
        if app.url.tsld($view[0].getAttribute("data-url")) is "2ch.net"
          """<img class="beicon" src="http://#{$1}" /><br />"""
        else
          $0
      #アンカーリンク
      .replace /(?:&gt;|＞){1,2}[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?(?:\s*,\s*[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?)*/g, ($0) ->
        str = $0.replace /[\uff10-\uff19]/g, ($0) ->
          String.fromCharCode($0.charCodeAt(0) - 65248)

        anchor = app.util.parse_anchor($0)
        disabled = anchor.target >= 25 or anchor.data.length is 0

        #rep_index更新
        if not disabled
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
  )
  html += """<div class="message">#{tmp}</div>"""

  tmp = ""
  if /(?:\　{5}|\　\ )(?!<br>|$)/i.test(res.message)
    tmp += " class=\"aa\""
  if attribute_data_id?
    tmp += " data-id=\"#{attribute_data_id}\""

  html = """<article#{tmp}>#{html}</article>"""

  html

app.view_thread._read_state_manager = ($view) ->
  view_url = $view.attr("data-url")
  board_url = app.url.thread_to_board(view_url)
  content = $view[0].querySelector(".content")

  #したらば、まちBBSの最新レス削除時対策
  cached_info = null
  if app.url.tsld(view_url) in ["livedoor.jp", "machi.to"]
    app.board.get_cached_res_count view_url, ({res_count, modified}) ->
      cached_info = {res_count, modified}

  #read_stateの取得
  get_read_state = $.Deferred (deferred) ->
    read_state_updated = false
    if (bookmark = app.bookmark.get(view_url))?.read_state?
      read_state = bookmark.read_state
      deferred.resolve({read_state, read_state_updated})
    else
      app.read_state.get(view_url).always (_read_state) ->
        read_state = _read_state or {received: 0, read: 0, last: 0, url: view_url}
        deferred.resolve({read_state, read_state_updated})
  .promise()

  #スレの描画時に、read_state関連のクラスを付与する
  $view.on "view_loaded", ->
    get_read_state.done ({read_state, read_state_updated}) ->
      content.querySelector(".last")?.classList.remove("last")
      content.querySelector(".read")?.classList.remove("read")
      content.querySelector(".received")?.classList.remove("received")

      content.children[read_state.last - 1]?.classList.add("last")
      content.children[read_state.read - 1]?.classList.add("read")
      content.children[read_state.received - 1]?.classList.add("received")

      $view.triggerHandler("read_state_attached")
    return

  get_read_state.done ({read_state, read_state_updated}) ->
    scan = ->
      received = content.childNodes.length
      #onbeforeunload内で呼び出された時に、この値が0になる場合が有る
      return if received is 0
      #したらば、まちBBSの最新レス削除時対策
      #スレ覧のキャッシュよりも新しいスレのデータを用いているにも関わらず、
      #キャッシュされているデータ内でのレス数の方が多い場合、
      #最新レスが削除されたためと判断し、receivedを変更する
      if cached_info?.modified < $view.data("last_updated") and
          received < cached_info.res_count
        received = cached_info.res_count

      bottom = content.scrollTop + content.clientHeight

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

    #スクロールされたら定期的にスキャンを実行する
    scroll_flg = false
    scroll_watcher = setInterval ->
      if scroll_flg
        scroll_flg = false
        scan()
        if read_state_updated
          app.message.send("read_state_updated", {board_url, read_state})
    , 250

    scan_and_save = ->
      scan()
      if read_state_updated
        app.read_state.set(read_state)
        app.bookmark.update_read_state(read_state)
        read_state_updated = false

    app.message.add_listener "request_update_read_state", (message) ->
      if not message.board_url? or message.board_url is board_url
        scan_and_save()
      return

    $view
      .find(".content")
        .on "scroll", ->
          scroll_flg = true
          return
      .end()

      .on "request_reload", ->
        scan_and_save()
        return

      .on "view_unload", ->
        clearInterval(scroll_watcher)
        window.removeEventListener("beforeunload", on_beforeunload)
        #ロード中に閉じられた場合、スキャンは行わない
        return if $view.hasClass("loading")
        scan_and_save()
        return
