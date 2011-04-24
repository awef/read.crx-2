app.view = {}

app.view.init = ->
  $("#body")
    .addClass("pane-3")

  $("#tab_a, #tab_b").tab()

  app.view.setup_resizer()

  $(document.documentElement)
    .delegate(".open_in_rcrx", "click", (e) ->
      e.preventDefault()
      app.message.send("open", {
        url: this.href or this.getAttribute("data-href")
      })
    )

app.view.load_sidemenu = (url) ->
  app.bbsmenu.get (res) ->
    if "data" of res
      frag = document.createDocumentFragment()
      for category in res.data
        h3 = document.createElement("h3")
        h3.innerText = category.title
        frag.appendChild(h3)

        ul = document.createElement("ul")
        for board in category.board
          li = document.createElement("li")
          a = document.createElement("a")
          a.className = "open_in_rcrx"
          a.innerText = board.title
          a.href = board.url
          li.appendChild(a)
          ul.appendChild(li)
        frag.appendChild(ul)

    $("#left_pane")
      .append(frag)
      .accordion()

app.view.setup_resizer = ->
  $("#tab_resizer")
    .bind "mousedown", (e) ->
      e.preventDefault()

      tab_a = document.getElementById("tab_a")
      min_height = 50
      max_height = document.body.offsetHeight - 50

      $("<div>", {css: {
        position: "absolute"
        left: 0
        top: 0
        width: "100%"
        height: "100%"
        "z-index": 999
        cursor: "row-resize"
      }})
        .bind("mousemove", (e) ->
          tab_a.style["height"] =
            Math.max(Math.min(e.pageY, max_height), min_height) + "px"
        )
        .bind("mouseup", -> $(this).remove())
        .appendTo("body")

app.view.open_board = (url) ->
  $container = $("#template > .view_board").clone()
  $container.attr("data-url", app.url.fix(url))
  $("#tab_a").tab("add", {element: $container[0], title: url})

  app.board.get url, (res) ->
    fn = (a) -> (if a < 10 then "0" else "") + a
    now = Date.now()

    if "data" of res
      tbody = $container.find("tbody")[0]
      for thread in res.data
        tr = document.createElement("tr")
        tr.className = "open_in_rcrx"
        tr.setAttribute("data-href", thread.url)

        td = document.createElement("td")
        tr.appendChild(td)

        td = document.createElement("td")
        td.innerText = thread.title
        tr.appendChild(td)

        td = document.createElement("td")
        td.innerText = thread.res_count
        tr.appendChild(td)

        td = document.createElement("td")
        tr.appendChild(td)

        td = document.createElement("td")
        thread_how_old = (now - thread.created_at) / (24 * 60 * 60 * 1000)
        td.innerText = (thread.res_count / thread_how_old).toFixed(1)
        tr.appendChild(td)

        td = document.createElement("td")
        date = new Date(thread.created_at)
        td.innerText = date.getFullYear() +
          "/" + fn(date.getMonth() + 1) +
          "/" + fn(date.getDate()) +
          " " + fn(date.getHours()) +
          ":" + fn(date.getMinutes())
        tr.appendChild(td)
        tr.appendChild(td)

        tbody.appendChild(tr)
      $container.find("table").tablesorter()

      if res.status is "error"
        $container
          .find(".message_bar")
            .removeClass("loading")
            .addClass("error")
            .text("板の読み込みに失敗しました。" +
              "キャッシュに残っていたデータを表示します。")
      else
        $container
          .find(".message_bar")
            .removeClass("loading")
            .text("")
    else
      $container
        .find(".message_bar")
          .removeClass("loading")
          .addClass("error")
          .text("板の読み込みに失敗しました。")

    app.history.add(url, url)

app.view.open_thread = (url) ->
  $container = $("#template > .view_thread").clone()
  $container.attr("data-url", app.url.fix(url))
  $("#tab_b").tab("add", {element: $container[0], title: url})
  res_num = 0

  app.thread.get url, (result) ->
    if "data" of result
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

        $container[0].appendChild(article)

      $("#tab_b")
        .tab("update_title", {
          tab_id: $container.attr("data-tab_id"),
          title: result.data.title
        })

      if result.status is "error"
        $container
          .find(".message_bar")
            .removeClass("loading")
            .addClass("error")
            .text("スレッドの読み込みに失敗しました。" +
              "キャッシュに残っていたデータを表示します。")
      else
        $container
          .find(".message_bar")
            .removeClass("loading")
            .text("")
    else
      $container
        .find(".message_bar")
          .removeClass("loading")
          .addClass("error")
          .text("スレッドの読み込みに失敗しました。")

    app.history.add(url, if "data" of result then result.data.title else url)

app.view.open_history = ->
  $container = $("#template > .view_history").clone()
  $("#tab_a").tab("add", {element: $container[0], title: "閲覧履歴"})

  app.history.get undefined, 500, (res) ->
    if "data" of res
      frag = document.createDocumentFragment()
      for val in res.data
        tr = document.createElement("tr")
        tr.setAttribute("data-href", val.url)
        tr.className = "open_in_rcrx"
        td = document.createElement("td")
        td.innerText = val.title
        tr.appendChild(td)
        td = document.createElement("td")
        td.innerText = val.date
        tr.appendChild(td)
        frag.appendChild(tr)
      $container.find("tbody").append(frag)

app.view.open_config = ->
  container_close = ->
    $container.fadeOut "fast", -> $container.remove()

  if $(".view_config:visible").length isnt 0
    app.log("debug", "app.view.open_config: 既に設定パネルが開かれています")
    return

  $container = $("#template > .view_config").clone()
  $container
    .bind("click", (e) ->
      if e.target.webkitMatchesSelector(".view_config")
        container_close()
    )
    .find("> div > .close_button")
      .bind("click", container_close)

  $container.hide().appendTo(document.body).fadeIn("fast")

app.view.open_bookmark_source_selector = ->
  if $(".view_bookmark_source_selector:visible").length isnt 0
    app.log("debug", "app.view.open_bookmark_source_selector: " +
      "既にブックマークフォルダ選択ダイアログが開かれています")
    return

  $view = $("#template > .view_bookmark_source_selector")
    .clone()
      .delegate ".node", "click", ->
        $(this)
          .closest(".view_bookmark_source_selector")
            .find(".selected")
              .removeClass("selected")
            .end()
            .find(".submit")
              .removeAttr("disabled")
            .end()
          .end()
          .addClass("selected")
      .find(".submit")
        .bind "click", ->
          bookmark_id = (
            $(this)
              .closest(".view_bookmark_source_selector")
                .find(".node.selected")
                  .attr("data-bookmark_id")
          )
          console.log bookmark_id
      .end()
      .appendTo(document.body)

  fn = (array_of_tree, ul) ->
    for tree in array_of_tree
      if "children" of tree
        li = document.createElement("li")
        span = document.createElement("span")
        span.className = "node"
        span.innerText = tree.title
        span.setAttribute("data-bookmark_id", tree.id)
        li.appendChild(span)
        ul.appendChild(li)

        cul = document.createElement("ul")
        li.appendChild(cul)

        fn(tree.children, cul)

  chrome.bookmarks.getTree (array_of_tree) ->
    fn(array_of_tree[0].children, $view.find(".node_list > ul")[0])

