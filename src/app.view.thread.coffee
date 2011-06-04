app.view.thread = {}

app.view.thread.open = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()
  $view = $("#template > .view_thread").clone()
  $view.attr("data-url", url)
  $view.attr("data-title", url)

  app.view.module.bookmark_button($view)
  app.view.module.link_button($view)
  app.view.module.reload_button($view)

  write = (param) ->
    param or= {}
    param.url = url
    param.title = $view.attr("data-title")
    open(
      "/write/write.html?#{app.url.build_param(param)}"
      undefined
      'width=600,height=300'
    )

  if /// ^http://\w+\.2ch\.net/|^http://jbbs\.livedoor\.jp/ ///.test(url)
    $view.find(".button_write").bind "click", ->
      write()
  else
    $view.find(".button_write").remove()

  $view.bind "request_reload", ->
    $view.find(".content").empty()
    $view.find(".loading_overlay").show()
    app.view.thread._draw($view)

  $view
    .delegate ".num", "click contextmenu", (e) ->
      if e.type is "contextmenu"
        e.preventDefault()

      app.defer =>
        $menu = $("#template > .view_thread_resmenu")
          .clone()
            .data("ui_contextmenu_source", this)
            .appendTo($view)
        $.contextmenu($menu, e.clientX, e.clientY)

    .delegate ".view_thread_resmenu > *", "click", ->
      $this = $(this)
      $res = $($this.parent().data("ui_contextmenu_source"))
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

      $(this).parent().remove()

  $("#tab_b").tab("add", element: $view[0], title: $view.attr("data-title"))

  $view
    .delegate ".anchor:not(.disabled)", "mouseenter", (e) ->
      this.textContent
        .replace /[\d０-９]+(?:-[\d０-９]+)?(?:\s*,\s*[\d０-９]+(?:-[\d０-９]+)?)*/g, ($0) ->
          str = $0.replace /[０-９]/g, ($0) ->
            String.fromCharCode($0.charCodeAt(0) - 65248)

          reg = /(\d+)(?:-(\d+))?/g
          res_list = $view.find(".content")[0].children
          res_list_length = res_list.length
          frag = document.createDocumentFragment()
          while (res = reg.exec(str))
            now = +res[1] - 1
            end = +(res[2] or res[1]) - 1
            while now <= end and now < res_list_length
              frag.appendChild(res_list[now].cloneNode(true))
              now++

          $popup = $view
            .find(".popup")
              .append(frag)
              .css(left: e.pageX + 20, top: e.pageY - 20)
              .show()

          $popup.css("left", e.pageX + 20 )
          $popup.css("top", Math.min(e.pageY, document.body.offsetHeight - $popup.outerHeight()) - 20)

    .delegate ".anchor:not(.disabled)", "mouseleave", ->
      $view.find(".popup").empty().hide()

    .delegate ".anchor:not(.disabled)", "click", ->
      tmp = /\d+/.exec(this.textContent)
      if tmp
        app.view.thread._jump_to_res($view, tmp[0], true)

  app.view.thread._read_state_manager($view)
  app.view.thread._draw($view)
    .always ->
      app.history.add(url, $view.attr("data-title"), opened_at)

app.view.thread._jump_to_res = (view, res_num, animate_flg) ->
  $content = $(view).find(".content")
  $target = $content.children(":nth-child(#{res_num})")
  if $target.length > 0
    if animate_flg
      $content.animate(scrollTop: $target[0].offsetTop)
    else
      $content.scrollTop($target[0].offsetTop)

app.view.thread._draw = ($view) ->
  url = $view.attr("data-url")
  deferred = $.Deferred()

  app.thread.get url, (result) ->
    $message_bar = $view.find(".message_bar")
    if result.status is "error"
      text = "スレッドの読み込みに失敗しました。"
      if "data" of result
        text += "キャッシュに残っていたデータを表示します。"
      $message_bar.addClass("error").text(text)

    if "data" of result
      thread = result.data
      $view.attr("data-title", thread.title)

      $view.find(".content").append(app.view.thread._draw_messages(thread))
      app.defer ->
        $view.triggerHandler("draw_content")

      $view
        .closest(".tab")
          .tab "update_title",
            tab_id: $view.attr("data-tab_id"),
            title: thread.title

      deferred.resolve()
    else
      deferred.reject()

    $view.find(".loading_overlay").fadeOut(100)
  deferred

app.view.thread._draw_messages = (thread) ->
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
    header.appendChild(other)

    message = document.createElement("div")
    message.className = "message"
    message.innerHTML = res.message
      .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/g, "")
      .replace(/(h)?(ttps?:\/\/[\w\-.!~*'();/?:@&=+$,%#]+)/g,
        '<a href="h$2" target="_blank" rel="noreferrer">$1$2</a>')
      .replace(///^\s*sssp://(img\.2ch\.net/ico/[\w\-_]+\.gif)\s*<br>///,
        '<img class="beicon" src="http://$1" /><br />')
      .replace(/(?:&gt;|＞){1,2}[\d０-９]+(?:-[\d０-９]+)?(?:\s*,\s*[\d０-９]+(?:-[\d０-９]+)?)*/g, ($0) ->
          str = $0.replace /[０-９]/g, ($0) ->
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
      )

    article.appendChild(message)

    frag.appendChild(article)
  frag

app.view.thread._read_state_manager = ($view) ->
  url = $view.attr("data-url")

  read_state = null

  promise_get_read_state = $.Deferred (deferred) ->
    if (bookmark = app.bookmark.get(url)) and "read_state" of bookmark
      read_state = bookmark.read_state
      deferred.resolve()
    else
      app.read_state.get(url)
        .always (_read_state) ->
          read_state = _read_state or {received: 0, read: 0, last: 0, url}
          deferred.resolve()
  .promise()

  promise_first_draw = $.Deferred (deferred) ->
    $view.one "draw_content", -> deferred.resolve()
  .promise()

  $.when(promise_get_read_state, promise_first_draw).done ->
    on_updated_draw = ->
      content = $view.find(".content")[0]

      app.view.thread._jump_to_res($view, read_state.last, false)

      res_read = content.children[read_state.read - 1]
      if res_read
        res_read.classList.add("read")

      res_received = content.children[read_state.received - 1]
      if res_received
        res_received.classList.add("received")

      read_state.received = content.children.length

    on_updated_draw()
    $view.bind("draw_content", on_updated_draw)

  promise_get_read_state.done ->
    scan = ->
      read_state.last = read_state.received
      content = $view[0].querySelector(".content")
      bottom = content.scrollTop + content.clientHeight
      is_updated = false

      for res, res_num in content.children
        if res.offsetTop > bottom
          last = res_num - 1
          if read_state.last isnt last
            read_state.last = last
            is_updated = true
          break

      if read_state.read < read_state.last
        read_state.read = read_state.last
        is_updated = true

      if is_updated
        app.read_state.set(read_state)

    scroll_flag = false
    scanner = setInterval((->
      if scroll_flag
        scan()
        scroll_flag = false
    ), 250)

    $view
      .find(".content")
        .bind "scroll", ->
          scroll_flag = true
      .end()

      .bind "tab_removed", ->
        clearInterval(scanner)
        scan()
