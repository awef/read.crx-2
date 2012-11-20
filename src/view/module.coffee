do ->
  if frameElement
    modules = [
      "History"
      "Thread"
      "board"
      "bookmark"
      "config"
      "module"
      "Ninja"
      "read_state"
      "url"
      "util"
    ]

    for module in modules
      app[module] = parent.app[module]
  return

app.view ?= {}

###*
@namespace app.view
@class View
@constructor
@param {Element} element
@requires jQuery
###
class app.view.View
  constructor: (@element) ->
    @$element = $element = $(@element)

    @_setupTheme()
    @_setupOpenInRcrx()
    return

  ###*
  @method _changeTheme
  @private
  @param {String} themeId
  ###
  _changeTheme: (themeId) ->
    # テーマ適用
    @$element.removeClass("theme_default theme_dark theme_none")
    @$element.addClass("theme_#{themeId}")
    return

  ###*
  @method _setupTheme
  @private
  ###
  _setupTheme: ->
    # テーマ適用
    @_changeTheme(app.config.get("theme_id"))

    # テーマ更新反映
    app.message.addListener "config_updated", (message) =>
      if message.key is "theme_id"
        @_changeTheme(message.val)
      return
    return

  ###*
  @method _insertUserCSS
  @private
  ###
  _insertUserCSS: ->
    style = document.createElement("style")
    style.textContent = app.config.get("user_css")
    document.head.appendChild(style)
    return

  ###*
  @method _setupOpenInRcrx
  @private
  ###
  _setupOpenInRcrx: ->
    # .open_in_rcrxリンクの処理
    @$element
      # Windowsのオートスクロール対策
      .on "mousedown", ".open_in_rcrx", (e) ->
        if e.which is 2
          e.preventDefault()
        return

      .on "click", ".open_in_rcrx", (e) ->
        e.preventDefault()
        url = @href or @getAttribute("data-href")
        title = @getAttribute("data-title") or @textContent
        howToOpen = app.util.get_how_to_open(e)
        newTab = app.config.get("always_new_tab") is "on"
        newTab or= howToOpen.new_tab or howToOpen.new_window
        background = howToOpen.background

        app.message.send("open", {url, new_tab: newTab, background, title})
        return
    return

###*
@namespace app.view
@class IframeView
@extends app.view.View
@constructor
@param {Element} element
###
class app.view.IframeView extends app.view.View
  constructor: (element) ->
    super(element)

    @_setupKeyboard()
    @_setupCommandBox()
    return

  ###*
  @method close
  ###
  close: ->
    parent.postMessage(
      JSON.stringify(type: "request_killme"),
      location.origin
    )
    return

  ###*
  @method execCommand
  @param {String} command
  ###
  execCommand: (command) ->
    # 数値コマンド
    if /^\d+$/.test(command)
      if @$element.is(".view_thread")
        target = Math.min(@$element.find(".content > article").length, +command)
        @$element.data("threadContent").scrollTo(target)
        @$element.data("threadContent").select(target)

    switch command
      when "up"
        if @$element.hasClass("view_thread")
          @$element.data("threadContent").selectPrev()
        else if @$element.hasClass("view_sidemenu")
          @$element.data("accordion").selectPrev()
        else if @$element.data("threadList")
          @$element.data("threadList").selectPrev()
      when "down"
        if @$element.hasClass("view_thread")
          @$element.data("threadContent").selectNext()
        else if @$element.hasClass("view_sidemenu")
          @$element.data("accordion").selectNext()
        else if @$element.data("threadList")
          @$element.data("threadList").selectNext()
      when "left"
        if @$element.hasClass("view_sidemenu")
          $a = @$element.find("li > a.selected")
          if $a.length is 1
            @$element.data("accordion").select($a.closest("ul").prev()[0])
      when "right"
        if @$element.hasClass("view_sidemenu")
          $a = @$element.find("h3.selected + ul a")
          if $a.length > 0
            @$element.data("accordion").select($a[0])
      when "focusUpFrame", "focusDownFrame", "focusLeftFrame", "focusRightFrame"
        app.message.send("requestFocusMove", {command}, parent)
      when "r"
        @$element.trigger("request_reload")
      when "q"
        @close()
      when "enter"
        @$element.find(".selected").trigger("click")
      when "help"
        app.message.send("showKeyboardHelp", null, parent)
    return

  ###*
  @method _setupCommandBox
  ###
  _setupCommandBox: ->
    that = @

    $("<input>", class: "command")
      .on "keydown", (e) ->
        # Enter
        if e.which is 13
          that.execCommand(e.target.value.replace(/[\s]/g, ""))
          that._closeCommandBox()
        # Esc
        else if e.which is 27
          that._closeCommandBox()
        return
      .hide()
      .appendTo(@$element)
    return

  ###*
  @method _openCommandBox
  ###
  _openCommandBox: ->
    @$element
      .find(".command")
        .data("lastActiveElement", document.activeElement)
        .show()
        .focus()
    return

  ###*
  @method _closeCommandBox
  ###
  _closeCommandBox: ->
    @$element
      .find(".command")
        .val("")
        .hide()
        .data("lastActiveElement")?.focus()
    return

  ###*
  @method _setupKeyboard
  @private
  ###
  _setupKeyboard: ->
    @$element.on "keydown", (e) =>
      # F5 or Ctrl+r or ⌘+r
      if e.which is 116 or (e.ctrlKey and e.which is 82) or (e.metaKey and e.which is 82)
        e.preventDefault()
        command = "r"
      else if e.ctrlKey or e.metaKey
        return

      # Esc (空白の入力欄に入力された場合)
      else if (
        e.which is 27 and
        e.target.nodeName in ["INPUT", "TEXTAREA"] and
        e.target.value is "" and
        not e.target.classList.contains("command")
      )
        @$element.find(".content").focus()

      # : (基本的に入力欄では発動しないが、空白の入力欄に入力された場合のみ例外)
      else if (
        e.which is 186 and
        (
          not (e.target.nodeName in ["INPUT", "TEXTAREA"]) or
          e.target.value is ""
        )
      )
        e.preventDefault()
        @_openCommandBox()

      # 入力欄内では発動しない系
      else if not (e.target.nodeName in ["INPUT", "TEXTAREA"])
        switch (e.which)
          # Enter
          when 13 then command = "enter"
          # h
          when 72
            if e.shiftKey
              command = "focusLeftFrame"
            else
              command = "left"
          # l
          when 76
            if e.shiftKey
              command = "focusRightFrame"
            else
              command = "right"
          # k
          when 75
            if e.shiftKey
              command = "focusUpFrame"
            else
              command = "up"
          # j
          when 74
            if e.shiftKey
              command = "focusDownFrame"
            else
              command = "down"
          # r
          when 82
            # Shift+r
            if e.shiftKey
              command = "r"
          # w
          when 87
            # Shift+w
            if e.shiftKey
              command = "q"
          # /
          when 191
            # ?
            if e.shiftKey
              command = "help"
            # /
            else
              e.preventDefault()
              $(".searchbox, form.search > input[type=\"text\"]").focus()

      if command?
        @execCommand(command)
      return
    return

###*
@namespace app.view
@class PaneContentView
@extends app.view.IframeView
@constructor
@param {Element} element
###
class app.view.PaneContentView extends app.view.IframeView
  constructor: (element) ->
    super(element)
    $element = @$element

    @_setupEventConverter()
    @_insertUserCSS()
    return

  ###*
  @method _setupEventConverter
  @private
  ###
  _setupEventConverter: ->
    window.addEventListener "message", (e) =>
      if e.origin is location.origin
        message = JSON.parse(e.data)

        # request_reload(postMessage) -> request_reload(event) 翻訳処理
        if message.type is "request_reload"
          if message.force_update is true
            @$element.trigger("request_reload", force_update: true)
          else
            @$element.trigger("request_reload")

        # tab_selected(postMessage) -> tab_selected(event) 翻訳処理
        else if message.type is "tab_selected"
          @$element.trigger("tab_selected")
      return

    @$element
      # request_focus送出処理
      .on "mousedown", (e) ->
        message =
          type: "request_focus"
          focus: true

        if e.target.nodeName in ["INPUT", "TEXTAREA"]
          message.focus = false

        parent.postMessage(JSON.stringify(message), location.origin)
        return

      # view_loaded翻訳処理
      .on "view_loaded", ->
        parent.postMessage(
          JSON.stringify(type: "view_loaded"),
          location.origin
        )
        return
    return

###*
@namespace app.view
@class TabContentView
@extends app.view.PaneContentView
@constructor
@param {Element} element
###
class app.view.TabContentView extends app.view.PaneContentView
  constructor: (element) ->
    super(element)

    @_setupTitleReporter()
    @_setupReloadButton()
    @_setupNavButton()
    @_setupBookmarkButton()
    @_setupSortItemSelector()
    @_setupToolMenu()
    return

  ###*
  @method _setupTitleReporter
  @private
  ###
  _setupTitleReporter: ->
    sendTitleUpdated = =>
      parent.postMessage(
        JSON.stringify(
          type: "title_updated"
          title: @$element.find("title").text()
        ),
        location.origin
      )
      return

    if @$element.find("title").text()
      sendTitleUpdated()

    @$element.find("title").on("DOMSubtreeModified", sendTitleUpdated)
    return

  ###*
  @method _setupReloadButton
  @private
  ###
  _setupReloadButton: ->
    that = @

    # View内リロードボタン
    @$element.find(".button_reload").on "click", ->
      if not $(this).hasClass("disabled")
        that.$element.trigger("request_reload")
      return
    return

  ###*
  @method _setupNavButton
  @private
  ###
  _setupNavButton: ->
    # 戻る/進むボタン管理
    parent.postMessage(
      JSON.stringify(type: "requestTabHistory"),
      location.origin
    )

    window.addEventListener "message", (e) =>
      if e.origin is location.origin
        message = JSON.parse(e.data)
        if message.type is "responseTabHistory"
          if message.history.current > 0
            @$element.find(".button_back").removeClass("disabled")

          if message.history.current < message.history.stack.length - 1
            @$element.find(".button_forward").removeClass("disabled")

          if (
            message.history.stack.length is 1 and
            app.config.get("always_new_tab") is "on"
          )
            @$element.find(".button_back, .button_forward").remove()
      return

    @$element.find(".button_back, .button_forward").on "click", ->
      $this = $(@)

      if not $this.is(".disabled")
        tmp = if $this.is(".button_back") then "Back" else "Forward"
        parent.postMessage(
          JSON.stringify(type: "requestTab#{tmp}"),
          location.origin
        )
      return
    return

  ###*
  @method _setupBookmarkButton
  @private
  ###
  _setupBookmarkButton: ->
    $button = @$element.find(".button_bookmark")

    if $button.length is 1
      url = @$element.attr("data-url")

      if ///^http://\w///.test(url)
        if app.bookmark.get(url)
          $button.addClass("bookmarked")
        else
          $button.removeClass("bookmarked")

        app.message.addListener "bookmark_updated", (message) ->
          if message.bookmark.url is url
            if message.type is "added"
              $button.addClass("bookmarked")
            else if message.type is "removed"
              $button.removeClass("bookmarked")
          return

        $button.on "click", =>
          if app.bookmark.get(url)
            app.bookmark.remove(url)
          else
            title = @$element.find("title").text() or url

            if @$element.hasClass("view_thread")
              resCount = @$element.find(".content").children().length

            if resCount? and resCount > 0
              app.bookmark.add(url, title, resCount)
            else
              app.bookmark.add(url, title)
          return
      else
        $button.remove()
    return

  ###*
  @method _setupSortItemSelector
  @private
  ###
  _setupSortItemSelector: ->
    $table = @$element.find(".table_sort")
    $selector = @$element.find(".sort_item_selector")

    $table.on "table_sort_updated", (e, ex) ->
      $selector
        .find("option")
          .filter(->
            String(ex.sort_attribute or ex.sort_index) is @textContent
          )
            .attr("selected", true)
      return

    $selector.on "change", ->
      selected = @children[@selectedIndex]
      config = {}

      config.sort_order = selected.getAttribute("data-sort_order") or "desc"

      if /^\d+$/.test(@value)
        config.sort_index = +@value
      else
        config.sort_attribute = @value

      if (tmp = selected.getAttribute("data-sort_type"))?
        config.sort_type = tmp

      $table.table_sort("update", config)
      return
    return

  ###*
  @method _setupToolMenu
  @private
  ###
  _setupToolMenu: ->
    that = @

    #メニューの表示/非表示制御
    @$element.find(".button_tool").on "click", ->
      if $(@).find("ul").toggle().is(":visible")
        app.defer ->
          that.$element.one "click contextmenu", (e) ->
            if not $(e.target).is(".button_tool")
              that.$element.find(".button_tool > ul").hide()
            return
          return
      return

    $(window).on "blur", =>
      @$element.find(".button_tool > ul").hide()
      return

    # Chromeで直接開く
    do =>
      url = @$element.attr("data-url")

      if url is "bookmark"
        url = "chrome-extension://eemcgdkfndhakfknompkggombfjjjeno/"
        url += "main.html##{app.config.get("bookmark_id")}"
      else if /^search:/.test(url)
        return
      else
        url = app.safe_href(url)

      @$element.find(".button_link > a").attr("href", url)
      return

    # タイトルをコピー
    @$element.find(".button_copy_title").on "click", =>
      app.clipboardWrite(@$element.find("title").text())
      return

    # URLをコピー
    @$element.find(".button_copy_url").on "click", =>
      app.clipboardWrite(@$element.attr("data-url"))
      return

    # タイトルとURLをコピー
    @$element.find(".button_copy_title_and_url").on "click", =>
      app.clipboardWrite(document.title + " " + @$element.attr("data-url"))
      return
    return
