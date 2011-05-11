app.view.open_bookmark = ->
  $view = $("#template > .view_bookmark").clone()
  $("#tab_a").tab("add", element: $view[0], title: "ブックマーク")
  $view.attr("data-url", "bookmark")

  $view.find("table").table_sort()

  $view
    .find(".button_reload")
      .bind "click", ->
        board_list = []
        for bookmark in app.bookmark.get_all()
          if bookmark.type is "thread"
            board_url = app.url.thread_to_board(bookmark.url)
            if board_list.indexOf(board_url) is -1
              board_list.push(board_url)

        fn = (result) ->
          if result
            if result.status is "success"
              console.log("done")
            else
              console.log("fail")

          if board_list.length > 0
            board_url = board_list[0]
            board_list.splice(0, 1)
            console.log("load_start: #{board_url}")
            app.board.get(board_url, fn)
        fn()

  now = Date.now()
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
        td.innerText = app.util.calc_heat(now, thread_created_at, bookmark.res_count)
      tr.appendChild(td)

      td = document.createElement("td")
      td.innerText = app.util.date_to_string(new Date(thread_created_at))
      tr.appendChild(td)

      frag.appendChild(tr)

  $view.find("tbody").append(frag)
