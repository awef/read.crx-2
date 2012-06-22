window.UI ?= {}

###*
@namespace UI
@class Tab
@constructor
@param {Element} container
###
class UI.Tab
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
    tab = @

    $(@element)
      .addClass("tab")
      .append(
        $("<div>", class: "tab_tabbar")
        $("<div>", class: "tab_container")
      )
      .on "mousewheel", ".tab_tabbar", (e) ->
        e.preventDefault()

        if e.originalEvent.wheelDelta > 0
          tmp = "previousSibling"
        else
          tmp = "nextSibling"

        next = tab.element.querySelector("li.tab_selected")?[tmp]

        if next
          tab.update(next.getAttribute("data-tabid"), selected: true)
        return

      .on "mousedown", ".tab_tabbar > li", (e) ->
        return if e.which is 3
        return if e.target.nodeName is "IMG"

        if e.which is 2
          tab.remove(@getAttribute("data-tabid"))
        else
          tab.update(@getAttribute("data-tabid"), selected: true)
        return

      .on "mousedown", ".tab_tabbar img", (e) ->
        e.preventDefault()
        return

      .on "click", ".tab_tabbar img", ->
        tab.remove(@parentNode.getAttribute("data-tabid"))
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
  ###
  update: (tabId, param) ->
    if typeof param.url is "string"
      $(@element)
        .find("li[data-tabid=\"#{tabId}\"]")
          .attr("data-tabsrc", param.url)
        .end()
        .find("iframe[data-tabid=\"#{tabId}\"]")
          .attr("src", param.url)
          .trigger("tab_urlupdated")

    if typeof param.title is "string"
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
      .find("[data-tabid=\"#{tabId}\"]")
        .filter("li.tab_selected")
          .each(->
            if next = @nextElementSibling or @previousElementSibling
              tab.update(next.getAttribute("data-tabid"), selected: true)
            return
          )
        .end()
        .filter(".tab_content")
          .trigger("tab_removed")
        .end()
      .remove()
    return
