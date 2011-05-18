`/** @namespace */`
app.view.thread = {}

app.view.thread.open = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()
  $view = $("#template > .view_thread").clone()
  $view.attr("data-url", url)

  app.view.module.bookmark_button($view)
  app.view.module.link_button($view)

  $view.find(".button_reload").bind "click", ->
    $view.find(".content").empty()
    $view.find(".loading_overlay").show()
    app.view.thread._draw($view)

  $("#tab_b").tab("add", element: $view[0], title: url)

  $view
    .delegate ".anchor:not(.disabled)", "mouseenter", (e) ->
      this.innerText
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

  app.view.thread._read_state_manager($view)
  app.view.thread._draw($view)
    .always (thread) ->
      app.history.add(url, (if thread then thread.title else url), opened_at)

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

      deferred.resolve(thread)
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
    num.innerText = res_key + 1
    header.appendChild(num)

    name = document.createElement("span")
    name.className = "name"
    name.innerHTML = res.name
      .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, "&lt;")
      .replace(/<\/b>(.*?)<b>/g, '<span class="ob">$1</span>')
    header.appendChild(name)

    mail = document.createElement("span")
    mail.className = "mail"
    mail.innerText = res.mail
    header.appendChild(mail)

    other = document.createElement("span")
    other.className = "other"
    other.innerText = res.other
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

  deferred_get_read_state = $.Deferred()
  deferred_first_draw = $.Deferred (deferred) ->
    $view.one "draw_content", -> deferred_first_draw.resolve()

  if (bookmark = app.bookmark.get(url)) and "read_state" of bookmark
    read_state = bookmark.read_state
    deferred_get_read_state.resolve()
  else
    app.read_state.get(url)
      .always (_read_state) ->
        read_state = _read_state or {received: 0, read: 0, last: 0, url}
        deferred_get_read_state.resolve()

  $.when(deferred_get_read_state, deferred_first_draw).done ->
    on_updated_draw = ->
      content = $view.find(".content")[0]

      res_last = content.children[read_state.last - 1]
      if res_last
        res_last.classList.add("last")
        content.scrollTop = res_last.offsetTop

      res_read = content.children[read_state.read - 1]
      if res_read
        res_read.classList.add("read")

      res_received = content.children[read_state.received - 1]
      if res_received
        res_received.classList.add("received")

      read_state.received = content.children.length

    on_updated_draw()
    $view.bind("draw_content", on_updated_draw)

  deferred_get_read_state.done ->
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
