window.UI ?= {}

###*
@namespace UI
@class Tab
@constructor
@param {Element} container
@requires jQuery
@requires UI.VirtualNotch
###
class UI.Tab
  "use strict"

  ###*
  @property _idCount
  @static
  @private
  @type Number
  ###
  @_idCount: 0

  ###*
  @method _id
  @static
  @private
  @return {String} id
  ###
  @_id: ->
    "tabId" + ++@_idCount

  constructor: (@element) ->
    @_recentClosed = []
    @_historyStore = {}

    tab = @

    $(@element)
      .addClass("tab")
      .append(
        $("<ul>", class: "tab_tabbar")
        $("<div>", class: "tab_container")
      )
      .find(".tab_tabbar")
        .on "notchedmousewheel", (e) ->
          e.preventDefault()

          if e.originalEvent.wheelDelta > 0
            tmp = "previousSibling"
          else
            tmp = "nextSibling"

          next = tab.element.querySelector("li.tab_selected")?[tmp]

          if next
            tab.update(next.getAttribute("data-tabid"), selected: true)
          return

        .on "mousedown", "li", (e) ->
          return if e.which is 3
          return if e.target.nodeName is "IMG"

          if e.which is 2
            tab.remove(@getAttribute("data-tabid"))
          else
            tab.update(@getAttribute("data-tabid"), selected: true)
          return

        .on "mousedown", "img", (e) ->
          e.preventDefault()
          return

        .on "click", "img", ->
          tab.remove(@parentNode.getAttribute("data-tabid"))
          return

    new UI.VirtualNotch(@element.querySelector(".tab_tabbar"))

    window.addEventListener "message", (e) =>
      return if e.origin isnt location.origin

      message = JSON.parse(e.data)

      return unless message.type in [
          "requestTabHistory"
          "requestTabBack"
          "requestTabForward"
        ]

      return unless @element.contains(e.source.frameElement)

      tabId = e.source.frameElement.getAttribute("data-tabid")
      history = @_historyStore[tabId]

      if message.type is "requestTabHistory"
        message = JSON.stringify({type: "responseTabHistory", history})
        e.source.postMessage(message, e.origin)

      else if message.type is "requestTabBack"
        if history.current > 0
          history.current--
          @update(tabId, {
            title: history.stack[history.current].title
            url: history.stack[history.current].url
            _internal: true
          })

      else if message.type is "requestTabForward"
        if history.current < history.stack.length - 1
          history.current++
          @update(tabId, {
            title: history.stack[history.current].title
            url: history.stack[history.current].url
            _internal: true
          })
      return
    return

  ###*
  @method getAll
  @return {Array}
  ###
  getAll: ->
    for li in @element.querySelectorAll("li")
      {
        tabId: li.getAttribute("data-tabid")
        url: li.getAttribute("data-tabsrc")
        title: li.title
        selected: li.classList.contains("tab_selected")
      }

  ###*
  @method getSelected
  @return {Object|null}
  ###
  getSelected: ->
    if li = @element.querySelector("li.tab_selected")
      {
        tabId: li.getAttribute("data-tabid")
        url: li.getAttribute("data-tabsrc")
        title: li.title
        selected: true
      }
    else
      null

  ###*
  @method add
  @param {String} url
  @param {Object} [param]
    @param {String} [param.title]
    @param {Boolean} [param.selected=true]
    @param {Boolean} [param.lazy=false]
  ###
  add: (url, param) ->
    param ?= {}
    param.title ?= url
    param.selected ?= true
    param.lazy ?= false

    tabId = Tab._id()

    @_historyStore[tabId] = {
      current: 0
      stack: [{url, title: url}]
    }

    #既存のタブが一つも無い場合、強制的にselectedオン
    if not @element.querySelector(".tab_tabbar > li")
      param.selected = true

    $("<li>")
      .attr("data-tabid": tabId, "data-tabsrc": url)
      .append(
        $("<span>")
        $("<img>", src: "/img/close_16x16.png", title: "閉じる")
      )
      .appendTo(@element.querySelector(".tab_tabbar"))

    $("<iframe>", {
        src: if param.lazy then "/view/empty.html" else url
        class: "tab_content"
        "data-tabid": tabId
      })
      .appendTo(@element.querySelector(".tab_container"))

    @update(tabId, title: param.title, selected: param.selected)

    tabId

  ###*
  @method update
  @param {String} tabId
  @param {Object} param
    @param {String} [param.url]
    @param {String} [param.title]
    @param {Boolean} [param.selected]
    @param {Boolean} [param._internal]
  ###
  update: (tabId, param) ->
    if typeof param.url is "string"
      unless param._internal
        history = @_historyStore[tabId]
        history.stack.splice(history.current + 1)
        history.stack.push(url: param.url, title: param.url)
        history.current++

      $(@element)
        .find("li[data-tabid=\"#{tabId}\"]")
          .attr("data-tabsrc", param.url)
        .end()
        .find("iframe[data-tabid=\"#{tabId}\"]")
          .trigger("tab_beforeurlupdate")
          .attr("src", param.url)
          .trigger("tab_urlupdated")

    if typeof param.title is "string"
      tmp = @_historyStore[tabId]
      tmp.stack[tmp.current].title = param.title

      $(@element)
        .find("li[data-tabid=\"#{tabId}\"]")
          .attr("title", param.title)
          .find("span")
            .text(param.title)

    if param.selected
      $iframe = (
        $(@element)
          .find(".tab_selected")
            .removeClass("tab_selected")
          .end()
          .find("[data-tabid=\"#{tabId}\"]")
            .addClass("tab_selected")
            .filter(".tab_content")
      )

      #遅延ロード指定のタブをロードする
      #連続でlazy指定のタブがaddされた時のために非同期処理
      app.defer =>
        if selectedTab = @getSelected()
          iframe = @element.querySelector("iframe[data-tabid=\"#{selectedTab.tabId}\"]")
          if iframe.getAttribute("src") isnt selectedTab.url
            iframe.src = selectedTab.url
        return
      $iframe.trigger("tab_selected")
    return

  ###*
  @method remove
  @param {String} tabId
  ###
  remove: (tabId) ->
    tab = @
    $(@element)
      .find("li[data-tabid=\"#{tabId}\"]")
        .each(->
          tabsrc = @getAttribute("data-tabsrc")

          for tmp, key in tab._recentClosed when tmp.url is tabsrc
            tab._recentClosed.splice(key, 1)
            break

          tab._recentClosed.push({
            tabId: @getAttribute("data-tabid")
            url: tabsrc
            title: @title
          })

          if tab._recentClosed.length > 50
            tmp = tab._recentClosed.shift()
            delete tab._historyStore[tmp.tabId]

          if @classList.contains("tab_selected")
            if next = @nextElementSibling or @previousElementSibling
              tab.update(next.getAttribute("data-tabid"), selected: true)
          return
        )
        .remove()
      .end()
      .find("iframe[data-tabid=\"#{tabId}\"]")
        .trigger("tab_removed")
      .remove()
    return

  ###*
  @method getRecentClosed
  @return {Array}
  ###
  getRecentClosed: ->
    app.deep_copy(@_recentClosed)

  ###*
  @method restoreClosed
  @param {String} tabId
  @return {String|null} tabId
  ###
  restoreClosed: (tabId) ->
    for tab, key in @_recentClosed when tab.tabId is tabId
      @_recentClosed.splice(key, 1)
      return @add(tab.url, title: tab.title)
    null
