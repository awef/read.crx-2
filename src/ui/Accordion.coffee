window.UI ?= {}

###*
@namespace UI
@class Accordion
@constructor
@param {Element} element
@requires jQuery
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
        .finish()
        .show()
      .end()
      .find(":header:not(.accordion_open) + *")
        .finish()
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
        .finish()
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
        .finish()
        .slideUp(duration)
    return



###*
@namespace UI
@class SelectableAccordion
@extends UI.Accordion
@constructor
@param {Element} element

.select対応のAccordion。
Accordionと違って汎用性が無い。
###
class UI.SelectableAccordion extends UI.Accordion
  constructor: (element) ->
    super(element)

    element.addEventListener "click", (e) =>
      @element.querySelector(".selected")?.classList.remove("selected")
      return
    return

  ###*
  @method getSelected
  @return {Element|null}
  ###
  getSelected: ->
    @element.querySelector("h3.selected, a.selected") or null

  ###*
  @method select
  @param {Element|number} target
  ###
  select: (target) ->
    if typeof target is "number"
      return

    @clearSelect()

    if target.nodeName is "H3"
      @close(target)
    else if target.nodeName is "A"
      targetHeader = target.parentElement.parentElement.previousElementSibling
      if not targetHeader.classList.contains("accordion_open")
        @open(targetHeader)

    target.classList.add("selected")
    target.scrollIntoViewIfNeeded()
    return

  ###*
  @method clearSelect
  ###
  clearSelect: ->
    @getSelected()?.classList.remove("selected")
    return

  ###*
  @method selectNext
  @param {number} [repeat = 1]
  ###
  selectNext: (repeat = 1) ->
    if current = @getSelected()
      for [0...repeat]
        prevCurrent = current

        if current.nodeName is "A" and current.parentNode.nextElementSibling
          current = current.parentNode.nextElementSibling.firstElementChild
        else
          if current.nodeName is "A"
            currentH3 = current.parentElement.parentElement.previousElementSibling
          else
            currentH3 = current

          nextH3 = currentH3.nextElementSibling
          while nextH3 and nextH3.nodeName isnt "H3"
            nextH3 = nextH3.nextElementSibling

          if nextH3
            if nextH3.classList.contains("accordion_open")
              current = nextH3.nextElementSibling.querySelector("li > a")
            else
              current = nextH3

        if current is prevCurrent
          break
    else
      current = @element.querySelector(".accordion_open + ul a")
      current or= @element.querySelector("h3")

    if current and current isnt @getSelected()
      @select(current)
    return

  ###*
  @method selectPrev
  @param {number} [repeat = 1]
  ###
  selectPrev: (repeat = 1) ->
    if current = @getSelected()
      for [0...repeat]
        prevCurrent = current

        if current.nodeName is "A" and current.parentNode.previousElementSibling
          current = current.parentNode.previousElementSibling.firstElementChild
        else
          if current.nodeName is "A"
            currentH3 = current.parentElement.parentElement.previousElementSibling
          else
            currentH3 = current

          prevH3 = currentH3.previousElementSibling
          while prevH3 and prevH3.nodeName isnt "H3"
            prevH3 = prevH3.previousElementSibling

          if prevH3
            if prevH3.classList.contains("accordion_open")
              current = prevH3.nextElementSibling.querySelector("li:last-child > a")
            else
              current = prevH3

        if current is prevCurrent
          break
    else
      current = @element.querySelector(".accordion_open + ul a")
      current or= @element.querySelector("h3")

    if current and current isnt @getSelected()
      @select(current)
    return
