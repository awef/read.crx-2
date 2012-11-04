window.UI ?= {}

###*
@namespace UI
@class Accordion
@constructor
@param {Element} element
###
class UI.Accordion
  constructor: (@element) ->
    accordion = @
    @$element = $(@element)

    @$element
      .addClass("accordion")
      .find(".accordion_open")
        .removeClass("accordion_open")
      .end()
      .find(":header + :not(:header)")
        .hide()

    @$element
      .on "click", "> :header", ->
        if @classList.contains("accordion_open")
          accordion.close(@)
        else
          accordion.open(@)
        return
    return

  ###*
  @method update
  ###
  update: ->
    @$element
      .find(".accordion_open + *")
        .stop(true, true)
        .show()
      .end()
      .find(":header:not(.accordion_open) + *")
        .stop(true, true)
        .hide()
    return

  ###*
  @method open
  @param {Element} header
  @param {Number} [duration=250]
  ###
  open: (header, duration = 250) ->
    accordion = @

    $(header)
      .addClass("accordion_open")
      .next()
        .stop(true, true)
        .slideDown(duration)
      .end()
      .siblings(".accordion_open")
        .each ->
          accordion.close(@, duration)
          return
    return

  ###*
  @method close
  @param {Element} header
  @param {Number} [duration=250]
  ###
  close: (header, duration = 250) ->
    $(header)
      .removeClass("accordion_open")
      .next()
        .stop(true, true)
        .slideUp(duration)
    return
