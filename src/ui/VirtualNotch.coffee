###*
@namespace UI
@class VirtualNotch
@constructor
@param {Element} element
@param {Number} threshold
###
class UI.VirtualNotch
  constructor: (@element, @threshold = 120) ->
    @element.addEventListener("mousewheel", @_onMouseWheel.bind(@))

    @_wheelDelta = 0
    @_lastMouseWheel = Date.now()
    @_interval = setInterval(@_onInterval.bind(@), 500)
    return

  _onInterval: ->
    if @_lastMouseWheel < Date.now() - 500
      @_wheelDelta = 0
    return

  _onMouseWheel: (e) ->
    @_wheelDelta += e.wheelDelta
    @_lastMouseWheel = Date.now()

    while Math.abs(@_wheelDelta) >= @threshold
      event = document.createEvent("MouseEvents")
      event.initEvent("notchedmousewheel")
      event.wheelDelta = @threshold * (if @_wheelDelta > 0 then 1 else -1)
      @_wheelDelta -= event.wheelDelta
      @element.dispatchEvent(event)
    return
