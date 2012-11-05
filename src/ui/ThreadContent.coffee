window.UI ?= {}

###*
@namespace UI
@class ThreadContent
@constructor
@param {String} URL
@param {Element} container
###
class UI.ThreadContent
  constructor: (@url, @container) ->
    ###*
    @property _$container
    @type Object
    @private
    ###
    @_$container = $(@container)

    ###*
    @property idIndex
    @type Object
    ###
    @idIndex = {}

    ###*
    @property repIndex
    @type Object
    ###
    @repIndex = {}

    ###*
    @property oneId
    @type null | String
    ###
    @oneId = null
    return

  ###*
  @method scrollTo
  @param {Number} resNum
  @param {Boolean} [animate=false]
  @param {Number} [offset=0]
  ###
  scrollTo: (resNum, animate = false, offset = 0) ->
    target = @container.childNodes[resNum - 1]
    if target
      return if @container.classList.contains("searching") and not target.classList.contains("search_hit")
      if animate
        @_$container.animate(scrollTop: target.offsetTop + offset)
      else
        @container.scrollTop = target.offsetTop + offset
    return

  ###*
  @method getRead
  @return {Number} 現在読んでいると推測されるレスの番号
  ###
  getRead: ->
    containerBottom = @container.scrollTop + @container.clientHeight
    read = @container.children.length
    for res, key in @container.children
      if res.offsetTop > containerBottom
        read = key - 1
        break
    read

  ###*
  @method getSelected
  @return {Number|null}
  ###
  getSelected: ->
    tmp = @container.querySelector("article.selected")
    if tmp
      +tmp.querySelector(".num").textContent
    else
      null

  ###*
  @method select
  @param {Number} resNum
  ###
  select: (resNum) ->
    @container.querySelector("article.selected")?.classList.remove("selected")
    @container.children[resNum - 1]?.classList.add("selected")
    return

  ###*
  @method selectNext
  ###
  selectNext: ->
    current = @getSelected()
    target = @container.children[current - 1]
    if not current or (
      # 現在選択されているレスが表示範囲外だった場合、それを無視する
      target.offsetTop + target.offsetHeight < @container.scrollTop or
      @container.scrollTop + @container.offsetHeight < target.offsetTop
    )
      current = @getRead()
      @select(current)
      target = @container.children[current - 1]

    if (
      @container.scrollTop + @container.offsetHeight >=
      target.offsetTop + target.offsetHeight
    ) and target.nextElementSibling
      target = target.nextElementSibling
      @select(current + 1)

    if (
      @container.scrollTop + @container.offsetHeight <
      target.offsetTop + target.offsetHeight
    )
      if target.offsetHeight >= @container.offsetHeight
        @container.scrollTop += @container.offsetHeight * 0.5
      else
        @container.scrollTop = (
          target.offsetTop -
          @container.offsetHeight +
          target.offsetHeight +
          10
        )
    else if not target.nextElementSibling
      @container.scrollTop += @container.offsetHeight * 0.5
    return

  ###*
  @method selectPrev
  ###
  selectPrev: ->
    current = @getSelected()
    target = @container.children[current - 1]
    if not current or (
      # 現在選択されているレスが表示範囲外だった場合、それを無視する
      target.offsetTop + target.offsetHeight < @container.scrollTop or
      @container.scrollTop + @container.offsetHeight < target.offsetTop
    )
      current = @getRead()
      @select(current)
      target = @container.children[current - 1]

    if (
      @container.scrollTop <= target.offsetTop and
      target.previousElementSibling
    )
      target = target.previousElementSibling
      @select(current - 1)

    if @container.scrollTop > target.offsetTop
      if target.offsetHeight >= @container.offsetHeight
        @container.scrollTop -= @container.offsetHeight * 0.5
      else
        @container.scrollTop = target.offsetTop - 10
    else if not target.previousElementSibling
      @container.scrollTop -= @container.offsetHeight * 0.5
    return

  ###*
  @method addItem
  @param {Object | Array}
  ###
  addItem: (items) ->
    unless Array.isArray(items)
      items = [items]

    resNum = @container.children.length

    do =>
      html = ""

      for res in items
        resNum++

        articleClass = []
        articleDataId = null

        if /(?:\u3000{5}|\u3000\u0020|[^>]\u0020\u3000)(?!<br>|$)/i.test(res.message)
          articleClass.push("aa")

        articleHtml = "<header>"

        #.num
        articleHtml += """<span class="num">#{resNum}</span>"""

        #.name
        articleHtml += """<span class="name"""
        if /^\s*([\d\uff10-\uff19]+)\s*$/.test(res.name)
          articleHtml += " name_num"
        tmp = (
          res.name
            .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, "&lt;")
            .replace(/<\/b>(.*?)<b>/g, """<span class="ob">$1</span>""")
        )
        articleHtml += """">#{tmp}</span>"""

        #.mail
        tmp = res.mail.replace(/<.*?(?:>|$)/g, "")
        articleHtml += """<span class="mail">#{tmp}</span>"""

        #.other
        tmp = (
          res.other
            #タグ除去
            .replace(/<.*?(?:>|$)/g, "")
            #.id
            .replace /(^| )(ID:(?!\?\?\?)[^ <>"']+)/, ($0, $1, $2) =>
              fixedId = $2.replace(/\u25cf$/, "") #末尾●除去

              articleDataId = fixedId

              if resNum is 1
                @oneId = fixedId

              if fixedId is @oneId
                articleClass.push("one")

              @idIndex[fixedId] = [] unless @idIndex[fixedId]?
              @idIndex[fixedId].push(resNum)

              """#{$1}<span class="id">#{$2}</span>"""
        )
        articleHtml += """<span class="other">#{tmp}</span>"""

        articleHtml += "</header>"

        tmp = (
          res.message
            #タグ除去
            .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/ig, "")
            #URLリンク
            .replace(/(h)?(ttps?:\/\/(?:[a-hj-zA-HJ-Z\d_\-.!~*'();\/?:@=+$,%#]|\&(?!(?:#(\d+)|#x([\dA-Fa-f]+)|([\da-zA-Z]+));)|[iI](?![dD]:)+)+)/g,
              '<a href="h$2" target="_blank">$1$2</a>')
            #Beアイコン埋め込み表示
            .replace ///^\s*sssp://(img\.2ch\.net/ico/[\w\-_]+\.gif)\s*<br>///, ($0, $1) =>
              if app.url.tsld(@url) is "2ch.net"
                """<img class="beicon" src="/img/dummy_1x1.png" data-src="http://#{$1}" /><br />"""
              else
                $0
            #アンカーリンク
            .replace /(?:&gt;|＞){1,2}[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?(?:\s*,\s*[\d\uff10-\uff19]+(?:-[\d\uff10-\uff19]+)?)*/g, ($0) =>
              anchor = app.util.parse_anchor($0)

              if anchor.target_count >= 25
                disabled = true
                disabledReason = "指定されたレスの量が極端に多いため、ポップアップを表示しません"
              else if anchor.target_count is 0
                disabled = true
                disabledReason = "指定されたレスが存在しません"
              else
                disabled = false

              #rep_index更新
              if not disabled
                for segment in anchor.segments
                  target = segment[0]
                  while target <= segment[1]
                    @repIndex[target] = [] unless @repIndex[target]?
                    @repIndex[target].push(resNum) unless resNum in @repIndex[target]
                    target++

              "<a href=\"javascript:undefined;\" class=\"anchor" +
              (if disabled then " disabled\" data-disabled_reason=\"#{disabledReason}\"" else "\"") +
              ">#{$0}</a>"
            #IDリンク
            .replace /id:(?:[a-hj-z\d_\+\/\.]|i(?!d:))+/ig, ($0) ->
              "<a href=\"javascript:undefined;\" class=\"anchor_id\">#{$0}</a>"
        )
        articleHtml += """<div class="message">#{tmp}</div>"""

        tmp = ""
        tmp += " class=\"#{articleClass.join(" ")}\""
        if articleDataId?
          tmp += " data-id=\"#{articleDataId}\""

        articleHtml = """<article#{tmp}>#{articleHtml}</article>"""
        html += articleHtml

      @container.insertAdjacentHTML("BeforeEnd", html)
      return

    #idカウント, .freq/.link更新
    do =>
      for id, index of @idIndex
        idCount = index.length
        for resNum in index
          elm = @container.childNodes[resNum - 1].getElementsByClassName("id")[0]
          elm.firstChild.nodeValue = elm.firstChild.nodeValue.replace(/(?:\(\d+\))?$/, "(#{idCount})")
          if idCount >= 5
            elm.classList.remove("link")
            elm.classList.add("freq")
          else if idCount >= 2
            elm.classList.add("link")
      return

    #参照関係再構築
    do =>
      for resKey, index of @repIndex
        res = @container.childNodes[resKey - 1]
        if res
          resCount = index.length
          if elm = res.getElementsByClassName("rep")[0]
            newFlg = false
          else
            newFlg = true
            elm = document.createElement("span")
          elm.textContent = "返信 (#{resCount})"
          elm.className = if resCount >= 5 then "rep freq" else "rep link"
          if newFlg
            res.getElementsByClassName("other")[0].appendChild(elm)
      return

    #サムネイル追加処理
    do =>
      addThumbnail = (sourceA, thumbnailPath) ->
        sourceA.classList.add("has_thumbnail")

        thumbnail = document.createElement("div")
        thumbnail.className = "thumbnail"

        thumbnailLink = document.createElement("a")
        thumbnailLink.href = app.safe_href(sourceA.href)
        thumbnailLink.target = "_blank"
        thumbnail.appendChild(thumbnailLink)

        thumbnailImg = document.createElement("img")
        thumbnailImg.src = "/img/dummy_1x1.png"
        thumbnailImg.setAttribute("data-src", thumbnailPath)
        thumbnailLink.appendChild(thumbnailImg)

        sib = sourceA
        while true
          pre = sib
          sib = pre.nextSibling
          if sib is null or sib.nodeName is "BR"
            if sib?.nextSibling?.classList?.contains("thumbnail")
              continue
            if not pre.classList?.contains("thumbnail")
              sourceA.parentNode.insertBefore(document.createElement("br"), sib)
            sourceA.parentNode.insertBefore(thumbnail, sib)
            break
        null

      configThumbnailSupported = app.config.get("thumbnail_supported") is "on"
      configThumbnailExt = app.config.get("thumbnail_ext") is "on"

      for a in @container.querySelectorAll(".message > a:not(.thumbnail):not(.has_thumbnail)")
        #サムネイル表示(対応サイト)
        if configThumbnailSupported
          #YouTube
          if res = /// ^http://
              (?:www\.youtube\.com/watch\?(?:.+&)?v=|youtu\.be/)
              ([\w\-]+).*
            ///.exec(a.href)
            addThumbnail(a, "http://img.youtube.com/vi/#{res[1]}/default.jpg")
          #ニコニコ動画
          else if res = /// ^http://(?:www\.nicovideo\.jp/watch/|nico\.ms/)
              (?:sm|nm)(\d+) ///.exec(a.href)
            tmp = "http://tn-skr#{parseInt(res[1], 10) % 4 + 1}.smilevideo.jp"
            tmp += "/smile?i=#{res[1]}"
            addThumbnail(a, tmp)

        #サムネイル表示(画像っぽいURL)
        if configThumbnailExt
          if /\.(?:png|jpe?g|gif|bmp|webp)(?:[\?#].*)?$/i.test(a.href)
            addThumbnail(a, a.href)
    return
