app.view_module = {}
app.view_module.searchbox_thread_title = ($view, target_col) ->
  $view.find(".searchbox_thread_title")
    .bind "input", ->
      $view.find("table")
        .table_search("search", {query: this.value, target_col})
    .bind "keyup", (e) ->
      if e.which is 27 #Esc
        this.value = ""
        $view.find("table").table_search("clear")

app.view_module.bookmark_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_bookmark")
  if ///^http://\w///.test(url)
    if app.bookmark.get(url)
      $button.addClass("bookmarked")
    else
      $button.removeClass("bookmarked")

    on_update = (message) ->
      if message.bookmark.url is url
        if message.type is "added"
          $button.addClass("bookmarked")
        else if message.type is "removed"
          $button.removeClass("bookmarked")

    app.message.add_listener("bookmark_updated", on_update)

    $view.bind "tab_removed", ->
      app.message.remove_listener("bookmark_updated", on_update)

    $button.bind "click", ->
      if app.bookmark.get(url)
        app.bookmark.remove(url)
      else
        app.bookmark.add(url, $view.attr("data-title") or url)
  else
    $button.remove()

app.view_module.link_button = ($view) ->
  url = $view.attr("data-url")
  $button = $view.find(".button_link")
  if ///^http://\w///.test(url)
    $("<a>", href: app.safe_href(url), target: "_blank")
      .appendTo($button)
  else
    $button.remove()

app.view_module.reload_button = ($view) ->
  $view.find(".button_reload").bind "click", ->
    if not $(this).hasClass("disabled")
      $view.trigger("request_reload")

app.view_module.board_contextmenu = ($view) ->
  $view
    #コンテキストメニュー 表示
    .delegate "tbody tr", "click, contextmenu", (e) ->
      if e.type is "contextmenu"
        e.preventDefault()

      app.defer =>
        $menu = $("#template > .view_module_board_contextmenu")
          .clone()
            .data("contextmenu_source", this)
            .appendTo($view)

        url = this.getAttribute("data-href")
        if app.bookmark.get(url)
          $menu.find(".add_bookmark").remove()
        else
          $menu.find(".del_bookmark").remove()

        $.contextmenu($menu, e.clientX, e.clientY)

    #コンテキストメニュー 項目クリック
    .delegate ".view_module_board_contextmenu > *", "click", ->
      $this = $(this)
      $tr = $($this.parent().data("contextmenu_source"))

      url = $tr.attr("data-href")
      if $view.is(".view_bookmark")
        title = $tr.find("td:nth-child(1)").text()
        res_count = +$tr.find("td:nth-child(2)").text()
      else if $view.is(".view_board")
        title = $tr.find("td:nth-child(2)").text()
        res_count = +$tr.find("td:nth-child(3)").text()
      else
        app.log("error", "app.view_module.board_contextmenu: 想定外の状況で呼び出されました")

      if $this.hasClass("add_bookmark")
        app.bookmark.add(url, title)
        #TODO 後でちゃんとする
        setTimeout ->
          app.bookmark.update_res_count(url, res_count)
        , 1000
      else if $this.hasClass("del_bookmark")
        app.bookmark.remove(url)

      $this.parent().remove()

app.view_sidemenu = {}
app.view_sidemenu.open = ->
  $view = $("#template > .view_sidemenu").clone()

  board_to_li = (board) ->
    li = document.createElement("li")
    a = document.createElement("a")
    a.className = "open_in_rcrx"
    a.textContent = board.title
    a.href = app.safe_href(board.url)
    li.appendChild(a)
    li

  bookmark_to_li = board_to_li

  #ブックマークがない場合はブックマーク表示自体を隠し、有る場合は表示する
  sh_bookmark = ->
    $tmp = $view.find(".view_sidemenu_bookmark")
    if $tmp.children().length is 0
      $tmp.hide()
    else
      $tmp.show()

  load = ->
    app.bbsmenu.get (res) ->
      if "data" of res
        frag = document.createDocumentFragment()
        for category in res.data
          h3 = document.createElement("h3")
          h3.textContent = category.title
          frag.appendChild(h3)

          ul = document.createElement("ul")
          for board in category.board
            ul.appendChild(board_to_li(board))
          frag.appendChild(ul)

      bookmark_frag = document.createDocumentFragment()
      for bookmark in app.bookmark.get_all()
        if bookmark.type is "board"
          bookmark_frag.appendChild(bookmark_to_li(bookmark))

      $view
        .find(".view_sidemenu_bookmark")
          .append(bookmark_frag)
        .end()
        .append(frag)
        .accordion()
      sh_bookmark()

  $view.bind "request_reload", ->
    $view.find(".view_sidemenu_bookmark").empty()
    $view.find("h3:not(:first-of-type), ul:not(:first-of-type)").remove()
    load()

  #ブックマーク更新時処理
  #TODO アンロード時にremove_listenerするよう改良
  app.message.add_listener "bookmark_updated", (message) ->
    if message.type is "added" and message.bookmark.type is "board"
      $view
        .find(".view_sidemenu_bookmark")
          .append(bookmark_to_li(message.bookmark))
      sh_bookmark()
    else if message.type is "removed"
      $view
        .find(".view_sidemenu_bookmark")
          .find("a[href=\"#{message.bookmark.url}\"]")
            .parent()
              .remove()
      sh_bookmark()

  load()

  $view

app.view_setup_resizer = ->
  $tab_a = $("#tab_a")
  tab_a = $tab_a[0]
  offset = $tab_a.outerHeight() - $tab_a.height()

  min_height = 50
  max_height = document.body.offsetHeight - 50

  tmp = app.config.get("tab_a_height")
  if tmp
    tab_a.style["height"] =
      Math.max(Math.min(tmp - offset, max_height), min_height) + "px"

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
            Math.max(Math.min(e.pageY - offset, max_height), min_height) + "px"
        .bind "mouseup", ->
          $(this).remove()
          app.config.set("tab_a_height", parseInt(tab_a.style["height"], 10))
        .appendTo("body")

app.view_history = {}

app.view_history.open = ->
  $view = $("#template > .view_history").clone()
  $view.attr("data-title", "閲覧履歴")

  app.view_module.reload_button($view)

  load = ->
    app.history.get(undefined, 500)
      .done (data) ->
        frag = document.createDocumentFragment()
        for val in data
          tr = document.createElement("tr")
          tr.setAttribute("data-href", val.url)
          tr.className = "open_in_rcrx"

          td = document.createElement("td")
          td.textContent = val.title
          tr.appendChild(td)

          td = document.createElement("td")
          td.textContent = app.util.date_to_string(new Date(val.date))
          tr.appendChild(td)
          frag.appendChild(tr)
        $view.find("tbody").append(frag)

  load()

  $view.bind "request_reload", ->
    $view.find("tbody").empty()
    load()

  $view

app.view_bookmark_source_selector = {}

app.view_bookmark_source_selector.open = ->
  if $(".view_bookmark_source_selector:visible").length isnt 0
    app.log("debug", "app.view_bookmark_source_selector.open: " +
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
        span.textContent = tree.title
        span.setAttribute("data-bookmark_id", tree.id)
        li.appendChild(span)
        ul.appendChild(li)

        cul = document.createElement("ul")
        li.appendChild(cul)

        fn(tree.children, cul)
    null

  chrome.bookmarks.getTree (array_of_tree) ->
    fn(array_of_tree[0].children, $view.find(".node_list > ul")[0])

