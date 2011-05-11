app.view.open_thread = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()
  $view = $("#template > .view_thread").clone()
  $view.attr("data-url", url)

  app.view.module.bookmark_button($view)
  app.view.module.link_button($view)

  $("#tab_b").tab("add", element: $view[0], title: url)

  deferred_draw_thread = $.Deferred()
  deferred_get_read_state = $.Deferred (deferred) ->
    app.read_state.get url, (res) ->
      if res.status is "success"
        deferred.resolve(res.data)
      else
        deferred.reject()

  read_state =
    received: 0
    read: 0
    last: 0
    get: ->
      received: this.received, read: this.read, last: this.last, url: url
    update: ->
      this.last = this.received
      container = $view[0].querySelector(".content")
      bottom = container.scrollTop + container.clientHeight

      for res, res_num in container.children
        if res.offsetTop > bottom
          this.last = res_num - 1
          break

      if this.read < this.last
        this.read = this.last

      app.read_state.set(read_state.get())

  deferred_get_read_state
    .done (tmp_read_state) ->
      read_state.received = tmp_read_state.length
      read_state.read = tmp_read_state.read
      read_state.last = tmp_read_state.last
    .always ->
      deferred_draw_thread
        .done (thread) ->
          scroll_flag = false
          read_state_watcher = setInterval((->
            if scroll_flag
              read_state.update()
              scroll_flag = false
          ), 250)

          read_state.received = thread.res.length
          content = $view.find(".content")[0]
          last_res = content.children[read_state.last - 1]
          if last_res
            content.scrollTop = last_res.offsetTop
          $view
            .find(".content")
              .bind "scroll", ->
                scroll_flag = true
            .end()
            .bind "tab_removed", ->
              clearInterval(read_state_watcher)
              read_state.update()

  app.thread.get url, (result) ->
    $message_bar = $view.find(".message_bar").removeClass("loading")
    if result.status is "error"
      text = "スレッドの読み込みに失敗しました。"
      if "data" of result
        text += "キャッシュに残っていたデータを表示します。"
      $message_bar.addClass("error").text(text)
    else
      $message_bar.text("")

    if "data" of result
      thread = result.data
      $view.attr("data-title", thread.title)

      $view
        .find(".content")
          .append(app.view._open_thread_draw_messages(thread))

      $view
        .closest(".tab")
          .tab "update_title",
            tab_id: $view.attr("data-tab_id"),
            title: thread.title

      deferred_draw_thread.resolve(thread)
      $view.find(".loading_overlay").fadeOut(100)
    app.history.add(url, (if "data" of result then result.data.title else url), opened_at)

app.view._open_thread_draw_messages = (thread) ->
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
