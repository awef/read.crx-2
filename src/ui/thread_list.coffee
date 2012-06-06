do ($ = jQuery) ->
  date_to_string = (date) ->
    fn = (a) -> (if a < 10 then "0" else "") + a

    date.getFullYear() +
    "/" + fn(date.getMonth() + 1) +
    "/" + fn(date.getDate()) +
    " " + fn(date.getHours()) +
    ":" + fn(date.getMinutes())

  calc_heat = (now, thread_created, res_count) ->
    (res_count / ((now - thread_created) / (24 * 60 * 60 * 1000))).toFixed(1)

  methods =
    create: (option) ->
      @flg =
        bookmark: false
        title: false
        board_title: false
        res: false
        unread: false
        heat: false
        created_date: false
        viewed_date: false

        bookmark_add_rm: !!option.bookmark_add_rm
        searchbox: undefined

      key_to_label =
        bookmark: "★"
        title: "タイトル"
        board_title: "板名"
        res: "レス数"
        unread: "未読数"
        heat: "勢い"
        created_date: "作成日時"
        viewed_date: "閲覧日時"

      $table = $(@table)
      $thead = $("<thead>").appendTo($table)
      $table.append("<tbody>")
      $tr = $("<tr>").appendTo($thead)

      for key in Object.keys(key_to_label) when key in option.th
        $("<th>", class: key, text: key_to_label[key]).appendTo($tr)
        @flg[key] = true

      #項目のツールチップ表示
      $table
        .on "mouseenter", "td", ->
          app.defer =>
            @title = @textContent
            return
          return
        .on "mouseleave", "td", ->
          @removeAttribute("title")
          return

      bookmark_selector = ":nth-child(#{$table.find("th.bookmark").index() + 1})"
      title_selector = ":nth-child(#{$table.find("th.title").index() + 1})"
      res_selector = ":nth-child(#{$table.find("th.res").index() + 1})"
      unread_selector = ":nth-child(#{$table.find("th.unread").index() + 1})"

      #ブックマーク更新時処理
      app.message.add_listener "bookmark_updated", (msg) =>
        return if msg.bookmark.type isnt "thread"

        if msg.type is "expired"
          $tr = $table.find("tr[data-href=\"#{msg.bookmark.url}\"]")
          if msg.bookmark.expired
            $tr.addClass("expired")
          else
            $tr.removeClass("expired")

        if @flg.bookmark
          if msg.type is "added"
            $tr = $table.find("tr[data-href=\"#{msg.bookmark.url}\"]")
            $tr.children(bookmark_selector).text("★")
          else if msg.type is "removed"
            $tr = $table.find("tr[data-href=\"#{msg.bookmark.url}\"]")
            $tr.children(bookmark_selector).text("")

        if @flg.bookmark_add_rm
          if msg.type is "added"
            $table.thread_list("add_item", {
              title: msg.bookmark.title
              url: msg.bookmark.url
              res_count: msg.bookmark.res_count or 0
              read_state: msg.bookmark.read_state or {url: msg.bookmark.url, read: 0, received: 0, last: 0}
              created_at: /\/(\d+)\/$/.exec(msg.bookmark.url)[1] * 1000
            })
          else if msg.type is "removed"
            $table.find("tr[data-href=\"#{msg.bookmark.url}\"]").remove()

        if @flg.res and msg.type is "res_count"
          $tr = $table.find("tr[data-href=\"#{msg.bookmark.url}\"]")
          $td = $tr.children(res_selector)
          old_res_count = +$td.text()
          $td.text(msg.bookmark.res_count)
          if @flg.unread
            $td = $tr.children(unread_selector)
            old_unread = +$td.text()
            unread = old_unread + (msg.bookmark.res_count - old_res_count)
            $td.text(unread or "")

        if @flg.title and msg.type is "title"
          $tr = $table.find("tr[data-href=\"#{msg.bookmark.url}\"]")
          $tr.children(title_selector).text(msg.bookmark.title)
        return

      #未読数更新
      if @flg.unread
        app.message.add_listener "read_state_updated", (msg) ->
          $tr = $table.find("tr[data-href=\"#{msg.read_state.url}\"]")
          if $tr.length is 1
            $res = $tr.children(res_selector)
            $unread = $tr.children(unread_selector)
            $unread.text(Math.max(+$res.text() - msg.read_state.read, 0) or "")
          return

      #リスト内検索
      if typeof option.searchbox is "object"
        title_index = $table.find("th.title").index()
        $searchbox = $(option.searchbox)

        $searchbox
          .closest(".view")
            .on "request_reload", ->
              $(option.searchbox).val("").triggerHandler("input")
              return
          .end()
          .on "input", ->
            if @value isnt ""
              $table.table_search("search", {
                query: @value, target_col: title_index})
              hit_count = $table.attr("data-table_search_hit_count")
              $(@).siblings(".hit_count").text(hit_count + "hit").show()
            else
              $table.table_search("clear")
              $(@).siblings(".hit_count").text("").hide()
            return
          .on "keyup", (e) ->
            if e.which is 27 #Esc
              @value = ""
              $(@).triggerHandler("input")
            return

      #コンテキストメニュー
      if @flg.bookmark or @flg.bookmark_add_rm
        do ->
          on_click= ->
            $this = $(@)
            $tr = $($this.parent().data("contextmenu_source"))

            thread_url = $tr.attr("data-href")
            thread_title = $tr.find(title_selector).text()
            thread_res = $tr.find(res_selector).text()

            if $this.hasClass("add_bookmark")
              app.bookmark.add(thread_url, thread_title, thread_res)
            else if $this.hasClass("del_bookmark")
              app.bookmark.remove(thread_url)

            $this.parent().remove()
            return

          $table
            .on "contextmenu", "tbody > tr", (e) ->
              if e.type is "contextmenu"
                e.preventDefault()

              app.defer =>
                $menu = $("#template > .thread_list_contextmenu")
                  .clone()
                    .data("contextmenu_source", @)
                    .appendTo($table.closest(".view"))

                url = @getAttribute("data-href")
                if app.bookmark.get(@getAttribute("data-href"))
                  $menu.find(".add_bookmark").remove()
                else
                  $menu.find(".del_bookmark").remove()

                $menu.one("click", "li", on_click)

                $.contextmenu($menu, e.clientX, e.clientY)
                return
              return
            return
      return

    add_item: (arg) ->
      unless Array.isArray(arg) then arg = [arg]

      tbody = @table.querySelector("tbody")
      now = Date.now()

      html = ""

      for item in arg
        tmp = "open_in_rcrx"
        if item.expired
          tmp += " expired"

        html += "<tr class=\"#{tmp}\""
        html += " data-href=\"#{app.escape_html(item.url)}\""
        html += " data-title=\"#{app.escape_html(item.title)}\""

        if item.thread_number?
          html += " data-thread_number=\"#{app.escape_html(""+item.thread_number)}\""

        html += ">"

        #ブックマーク状況
        if @flg.bookmark
          html += "<td>"
          if app.bookmark.get(item.url)
            html += "★"
          html += "</td>"

        #タイトル
        if @flg.title
          html += "<td>#{app.escape_html(item.title)}</td>"

        #板名
        if @flg.board_title
          html += "<td>#{app.escape_html(item.board_title)}</td>"

        #レス数
        if @flg.res
          html += "<td>"
          if item.res_count > 0
            html += app.escape_html(""+item.res_count)
          html += "</td>"

        #未読数
        if @flg.unread
          html += "<td>"
          if item.read_state and item.res_count > item.read_state.read
            html += app.escape_html(""+(item.res_count - item.read_state.read))
          html += "</td>"

        #勢い
        if @flg.heat
          html += "<td>"
          html += app.escape_html(calc_heat(now, item.created_at, item.res_count))
          html += "</td>"

        #作成日時
        if @flg.created_date
          html += "<td>"
          html += app.escape_html(date_to_string(new Date(item.created_at)))
          html += "</td>"

        #閲覧日時
        if @flg.viewed_date
          html += "<td>"
          html += app.escape_html(date_to_string(new Date(item.date)))
          html += "</td>"

      tbody.insertAdjacentHTML("BeforeEnd", html)
      return

    empty: ->
      $(@table).find("tbody").empty()
      return

  $.fn.thread_list = (method, param...) ->
    unless $(@).data("thread_list:this")?
      $(@).data("thread_list:this", {table: @[0]})
    methods[method].apply($(@).data("thread_list:this"), param)
    @

  return
