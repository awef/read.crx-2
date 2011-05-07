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

app.view.open_history = ->
  $view = $("#template > .view_history").clone()
  $("#tab_a").tab("add", element: $view[0], title: "閲覧履歴")

  app.history.get undefined, 500, (res) ->
    if "data" of res
      fn = (a) -> (if a < 10 then "0" else "") + a

      frag = document.createDocumentFragment()
      for val in res.data
        tr = document.createElement("tr")
        tr.setAttribute("data-href", val.url)
        tr.className = "open_in_rcrx"

        td = document.createElement("td")
        td.innerText = val.title
        tr.appendChild(td)

        td = document.createElement("td")
        date = new Date(val.date)
        td.innerText = date.getFullYear() +
          "/" + fn(date.getMonth() + 1) +
          "/" + fn(date.getDate()) +
          " " + fn(date.getHours()) +
          ":" + fn(date.getMinutes())
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

