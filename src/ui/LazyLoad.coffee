window.UI ?= {}

###*
@namespace UI
@class LazyLoad
@constructor
@param {Element} container
###
class UI.LazyLoad
  @UPDATE_INTERVAL: 200

  constructor: (@container) ->
    ###*
    @property container
    @type Element
    ###
    ###*
    @property _scroll
    @private
    @type Boolean
    ###
    @_scroll = false

    ###*
    @property _imgs
    @private
    @type Array
    ###
    @_imgs = []

    ###*
    @property _updateInterval
    @private
    @type Number|null
    ###
    @_updateInterval = null

    @container.addEventListener("scroll", @_onScroll.bind(@))
    @scan()
    return

  ###*
  @method _onScroll
  @private
  ###
  _onScroll: ->
    @_scroll = true
    return

  ###*
  @method _load
  @private
  @param {Element} img
  ###
  _load: (img) ->
    newIMG = document.createElement("img")
    for attr in img.attributes when attr.name isnt "data-src"
      newIMG.setAttribute(attr.name, attr.value)

    $(newIMG).one "load error", (e) ->
      $(img).replaceWith(@)
      if e.type is "load"
        $(@).trigger("lazyload-load").hide().fadeIn()
      return

    newIMG.src = img.getAttribute("data-src")
    img.removeAttribute("data-src")
    return

  ###*
  @method _watch
  @private
  ###
  _watch: ->
    if @_updateInterval is null
      @_updateInterval = setInterval((=>
        if @_scroll
          @update()
          @_scroll = false
        return
      ), LazyLoad.UPDATE_INTERVAL)
    return

  ###*
  @method _unwatch
  @private
  ###
  _unwatch: ->
    if @_updateInterval isnt null
      clearInterval(@_updateInterval)
      @_updateInterval = null
    return

  ###*
  @method scan
  ###
  scan: ->
    @_imgs = Array::slice.call(@container.querySelectorAll("img[data-src]"))
    if @_imgs.length > 0
      @update()
      @_watch()
    else
      @_unwatch()
    return

  ###*
  @method update
  ###
  update: ->
    @_imgs = for img in @_imgs
      if img.offsetWidth isnt 0 #imgが非表示の時はロードしない
        top = 0
        current = img

        while current isnt null and current isnt @container
          top += current.offsetTop
          current = current.offsetParent

        if not (top + img.offsetHeight < @container.scrollTop or
            @container.scrollTop + @container.clientHeight < top)
          @_load(img)
          continue
      img

    if @_imgs.length is 0
      @_unwatch()
    return
