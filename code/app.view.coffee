`/** @namespace */`
app.view = {}

app.view.init = ->
  $("#body")
    .addClass("pane-3")

  $("#tab_a, #tab_b").tab()

  app.view.setup_resizer()

  $(document.documentElement)
    .delegate ".open_in_rcrx", "click", (e) ->
      e.preventDefault()
      app.message.send "open",
        url: this.href or this.getAttribute("data-href")

app.view.module = {}
app.view.module.bookmark_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_bookmark")
  if ///^http://\w///.test(url)
    update = ->
      if app.bookmark.get(url)
        $button.addClass("bookmarked")
      else
        $button.removeClass("bookmarked")

    update()

    app.message.add_listener("bookmark_updated", update)

    $view.bind "tab_removed", ->
      app.message.remove_listener("bookmark_updated", update)

    $button.bind "click", ->
      if app.bookmark.get(url)
        app.bookmark.remove(url)
      else
        app.bookmark.add(url, $view.attr("data-title") or url)
  else
    $button.remove()

app.view.module.link_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_link")
  if ///^http://\w///.test(url)
    $("<a>", title: "Chromeで直接開く", href: url, target: "_blank")
      .appendTo($button)
  else
    $button.remove()

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
  tab_a = document.getElementById("tab_a")
  min_height = 50
  max_height = document.body.offsetHeight - 50

  tmp = app.config.get("tab_a_height")
  if tmp
    tab_a.style["height"] =
      Math.max(Math.min(tmp, max_height), min_height) + "px"

  $("#tab_resizer")
    .bind "mousedown", (e) ->
      e.preventDefault()

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
        .bind "mousemove", (e) ->
          tab_a.style["height"] =
            Math.max(Math.min(e.pageY, max_height), min_height) + "px"
        .bind "mouseup", ->
          $(this).remove()
          app.config.set("tab_a_height", parseInt(tab_a.style["height"], 10))
        .appendTo("body")

app.view.open_bookmark = ->
  $view = $("#template > .view_bookmark").clone()
  $("#tab_a").tab("add", element: $view[0], title: "ブックマーク")
  $view.attr("data-url", "bookmark")

  frag = document.createDocumentFragment()

  for bookmark in app.bookmark.get_all()
    if bookmark.type is "thread"
      tr = document.createElement("tr")
      tr.className = "open_in_rcrx"
      tr.setAttribute("data-href", bookmark.url)

      thread_created_at = +/// /(\d+)/$ ///.exec(bookmark.url)[1] * 1000
      td = document.createElement("td")
      td.innerText = bookmark.title
      tr.appendChild(td)

      td = document.createElement("td")
      td.innerText = bookmark.res_count or 0
      tr.appendChild(td)

      td = document.createElement("td")
      if (
          typeof bookmark.res_count is "number" and
          bookmark.read_state and typeof bookmark.read_state.read is "number"
      )
        td.innerText = bookmark.res_count - bookmark.read_state.read
      tr.appendChild(td)

      td = document.createElement("td")
      if typeof bookmark.res_count is "number"
        thread_how_old = (Date.now() - thread.created_at) / (24 * 60 * 60 * 1000)
        td.innerText = (bookmark.res_count / thread_how_old).toFixed(1)
      tr.appendChild(td)

      td = document.createElement("td")
      date = new Date(+/// /(\d+)/$ ///.exec(bookmark.url)[1] * 1000)
      td.innerText = app.util.date_to_string(date)
      tr.appendChild(td)

      frag.appendChild(tr)

  $view.find("tbody").append(frag)

app.view.open_history = ->
  $view = $("#template > .view_history").clone()
  $("#tab_a").tab("add", element: $view[0], title: "閲覧履歴")

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
        td.innerText = app.util.date_to_string(new Date(val.date))
        tr.appendChild(td)
        frag.appendChild(tr)
      $view.find("tbody").append(frag)

app.view.open_config = ->
  container_close = ->
    $view.fadeOut "fast", -> $view.remove()

  if $(".view_config:visible").length isnt 0
    app.log("debug", "app.view.open_config: 既に設定パネルが開かれています")
    return

  $view = $("#template > .view_config").clone()
  $view
    .bind("click", (e) ->
      if e.target.webkitMatchesSelector(".view_config")
        container_close()
    )
    .find("> div > .close_button")
      .bind("click", container_close)

  $view.hide().appendTo(document.body).fadeIn("fast")

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
          app.bookmark.change_source(bookmark_id)
          $(this)
            .closest(".view_bookmark_source_selector")
              .fadeOut "fast", ->
                $(this).remove()
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

