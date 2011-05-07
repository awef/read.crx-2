app.view.open_thread = (url) ->
  url = app.url.fix(url)
  opened_at = Date.now()
  $view = $("#template > .view_thread").clone()
  $view.attr("data-url", url)

  app.view.module.bookmark_button($view)
  app.view.module.link_button($view)

  $("#tab_b").tab("add", element: $view[0], title: url)
  res_num = 0

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
      received: this.received, read: this.read, last: this.last
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

  deferred_get_read_state
    .done (tmp_read_state) ->
      read_state.received = tmp_read_state.length
      read_state.read = tmp_read_state.read
      read_state.last = tmp_read_state.last
    .always ->
      deferred_draw_thread
        .done (thread) ->
          read_state.received = thread.res.length
          content = $view.find(".content")[0]
          last_res = content.children[read_state.last - 1]
          if last_res
            content.scrollTop = last_res.offsetTop
          $view
            .find(".content")
              .bind "scroll", ->
                read_state.update()
            .end()
            .bind "tab_removed", ->
              read_state.update()
              app.read_state.set(url, read_state.get())

  $.when(deferred_get_read_state, deferred_draw_thread)
    .done (tmp_read_state, thread) ->
      read_state.received = thread.res.length
      read_state.read = tmp_read_state.read
      read_state.last = tmp_read_state.last
      content = $view.find(".content")[0]
      last_res = content.children[read_state.last - 1]
      if last_res
        content.scrollTop = last_res.offsetTop

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
      $view.attr("data-title", result.data.title)

      frag = document.createDocumentFragment()
      for res in result.data.res
        res_num++

        article = document.createElement("article")
        if /\　\ (?!<br>|$)/i.test(res.message)
          article.className = "aa"

        header = document.createElement("header")
        article.appendChild(header)

        num = document.createElement("span")
        num.className = "num"
        num.innerText = res_num
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
          .replace(/^\s*sssp:\/\/(img\.2ch\.net\/ico\/[\w\-_]+\.gif)\s*<br>/,
            '<img class="beicon" src="http://$1" /><br />')
        article.appendChild(message)

        frag.appendChild(article)

      $view
        .find(".content")
          .append(frag)

      $view
        .closest(".tab")
          .tab "update_title",
            tab_id: $view.attr("data-tab_id"),
            title: result.data.title

      deferred_draw_thread.resolve(result.data)
    app.history.add(url, (if "data" of result then result.data.title else url), opened_at)
