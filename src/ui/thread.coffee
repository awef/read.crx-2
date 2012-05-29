do ($ = jQuery) ->
  methods =
    scroll_to: (res_num, animate_flg, offset = -10) ->
      target = @container.childNodes[res_num - 1]
      if target
        return if @container.classList.contains("searching") and not target.classList.contains("search_hit")
        if animate_flg
          @$container.animate(scrollTop: target.offsetTop + offset)
        else
          @container.scrollTop = target.offsetTop + offset
      return

    get_read: ->
      container_bottom = @container.scrollTop + @container.clientHeight
      read = @container.children.length
      for res, key in @container.children
        if res.offsetTop > container_bottom
          read = key - 1
          break
      read

    add_item: (items) ->
      unless Array.isArray(items)
        items = [items]

      res_num = @container.children.length

      do =>
        html = ""

        for res in items
          res_num++

          attribute_data_id = null
          article_class = []

          if /(?:\u3000\u3000\u3000\u3000\u3000|\u3000\u0020|[^>]\u0020\u3000)(?!<br>|$)/i.test(res.message)
            article_class.push("aa")

          item_html = "<header>"

          #.num
          item_html += """<span class="num">#{res_num}</span>"""

          #.name
          tmp = (
            res.name
              .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, "&lt;")
              .replace(/<\/b>(.*?)<b>/g, """<span class="ob">$1</span>""")
          )
          item_html += """<span class="name">#{tmp}</span>"""

          #.mail
          tmp = res.mail.replace(/<.*?(?:>|$)/g, "")
          item_html += """<span class="mail">#{tmp}</span>"""

          #.other
          tmp = (
            res.other
              #タグ除去
              .replace(/<.*?(?:>|$)/g, "")
              #.id
              .replace /(^| )(ID:(?!\?\?\?)[^ <>"']+)/, ($0, $1, $2) =>
                fixed_id = $2.replace(/\u25cf$/, "") #末尾●除去

                attribute_data_id = fixed_id

                if res_num is 1
                  @one_id = fixed_id

                if fixed_id is @one_id
                  article_class.push("one")

                @id_index[fixed_id] = [] unless @id_index[fixed_id]?
                @id_index[fixed_id].push(res_num)

                """#{$1}<span class="id">#{$2}</span>"""
          )
          item_html += """<span class="other">#{tmp}</span>"""

          item_html += "</header>"

          tmp = (
            res.message
              #タグ除去
              .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/ig, "")
              #URLリンク
              .replace(/(h)?(ttps?:\/\/(?:[a-hj-zA-HJ-Z\d_\-.!~*'();\/?:@=+$,%#]|\&(?!(?:#(\d+)|#x([\dA-Fa-f]+)|([\da-zA-Z]+));)|[iI](?![dD]:)+)+)/g,
                '<a href="h$2" target="_blank" rel="noreferrer">$1$2</a>')
              #Beアイコン埋め込み表示
              .replace ///^\s*sssp://(img\.2ch\.net/ico/[\w\-_]+\.gif)\s*<br>///, ($0, $1) =>
                console.log "hoge"
                console.log @url
                if app.url.tsld(@url) is "2ch.net"
                  """<img class="beicon" src="http://#{$1}" /><br />"""
                else
                  $0
              #アンカーリンク
              .replace /(?:&gt;|＞){1,2}[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?(?:\s*,\s*[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?)*/g, ($0) =>
                anchor = app.util.parse_anchor($0)

                if anchor.target_count >= 25
                  disabled = true
                  disabled_reason = "指定されたレスの量が極端に多いため、ポップアップを表示しません"
                else if anchor.target_count is 0
                  disabled = true
                  disabled_reason = "指定されたレスが存在しません"
                else
                  disabled = false

                #rep_index更新
                if not disabled
                  for segment in anchor.segments
                    target = segment[0]
                    while target <= segment[1]
                      @rep_index[target] = [] unless @rep_index[target]?
                      @rep_index[target].push(res_num) unless res_num in @rep_index[target]
                      target++

                "<a href=\"javascript:undefined;\" class=\"anchor" +
                (if disabled then " disabled\" data-disabled_reason=\"#{disabled_reason}\"" else "\"") +
                ">#{$0}</a>"
              #IDリンク
              .replace /id:(?:[a-hj-z\d_\+\/\.]|i(?!d:))+/ig, ($0) ->
                "<a href=\"javascript:undefined;\" class=\"anchor_id\">#{$0}</a>"
          )
          item_html += """<div class="message">#{tmp}</div>"""

          tmp = ""
          tmp += " class=\"#{article_class.join(" ")}\""
          if attribute_data_id?
            tmp += " data-id=\"#{attribute_data_id}\""

          item_html = """<article#{tmp}>#{item_html}</article>"""
          html += item_html

        @container.insertAdjacentHTML("BeforeEnd", html)
        return

      #idカウント, .freq/.link更新
      do =>
        for id, index of @id_index
          id_count = index.length
          for res_num in index
            elm = @container.childNodes[res_num - 1].getElementsByClassName("id")[0]
            elm.firstChild.nodeValue = elm.firstChild.nodeValue.replace(/(?:\(\d+\))?$/, "(#{id_count})")
            if id_count >= 5
              elm.classList.remove("link")
              elm.classList.add("freq")
            else if id_count >= 2
              elm.classList.add("link")
        return

      #参照関係再構築
      do =>
        for res_key, index of @rep_index
          res = @container.childNodes[res_key - 1]
          if res
            res_count = index.length
            if elm = res.getElementsByClassName("rep")[0]
              new_flg = false
            else
              new_flg = true
              elm = document.createElement("span")
            elm.textContent = "返信 (#{res_count})"
            elm.className = if res_count >= 5 then "rep freq" else "rep link"
            if new_flg
              res.getElementsByClassName("other")[0].appendChild(elm)
        return

      return

    init: ({@url}) ->
    id_index: -> @id_index
    rep_index: -> @rep_index
    one_id: -> @one_id

  $.fn.thread = (method, param...) ->
    if method is "init"
      @data("thread:this", {
        $container: @
        container: @[0]
        id_index: {}
        rep_index: {}
        one_id: null
      })
    res = methods[method].apply(@data("thread:this"), param)
    if res is undefined then @ else res

  return
