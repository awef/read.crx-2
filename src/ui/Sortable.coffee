window.UI ?= {}

###*
@namespace UI
@class Sortable
@constructor
@param {Element} container
@parma {Object} [option]
  @param {String} [option.exclude]
###
class UI.Sortable
  "use strict"

  constructor: (@container, option = {}) ->
    sorting = false
    start = {}
    target = null

    @container.classList.add("sortable")

    overlay = document.createElement("div")
    overlay.classList.add("sortable_overlay")

    overlay.addEventListener "contextmenu", (e) ->
      e.preventDefault()
      return

    overlay.addEventListener "mousemove", (e) =>
      if not sorting
        start.x = e.pageX
        start.y = e.pageY
        sorting = true

      targetCenter =
        x: target.offsetLeft + target.offsetWidth / 2
        y: target.offsetTop + target.offsetHeight / 2

      tmp = @container.firstElementChild

      while tmp
        if tmp isnt target and not (
          targetCenter.x < tmp.offsetLeft or
          targetCenter.y < tmp.offsetTop or
          targetCenter.x > tmp.offsetLeft + tmp.offsetWidth or
          targetCenter.y > tmp.offsetTop + tmp.offsetHeight
        )
          if (
            target.compareDocumentPosition(tmp) is 4 and
            (
              targetCenter.x > tmp.offsetLeft + tmp.offsetWidth / 2 or
              targetCenter.y > tmp.offsetTop + tmp.offsetHeight / 2
            )
          )
            cacheX = target.offsetLeft
            cacheY = target.offsetTop
            tmp.insertAdjacentElement("afterend", target)
            start.x += target.offsetLeft - cacheX
            start.y += target.offsetTop - cacheY
          else if (
            targetCenter.x < tmp.offsetLeft + tmp.offsetWidth / 2 or
            targetCenter.y < tmp.offsetTop + tmp.offsetHeight / 2
          )
            cacheX = target.offsetLeft
            cacheY = target.offsetTop
            tmp.insertAdjacentElement("beforebegin", target)
            start.x += target.offsetLeft - cacheX
            start.y += target.offsetTop - cacheY
          break
        tmp = tmp.nextElementSibling

      target.style.left = "#{e.pageX - start.x}px"
      target.style.top = "#{e.pageY - start.y}px"
      return

    onHoge = ->
      # removeするとmouseoutも発火するので二重に呼ばれる
      sorting = false
      if target?
        target.classList.remove("sortable_dragging")
        target.style.left = "initial"
        target.style.top = "initial"
        target = null
        @parentNode.removeChild(@)
      return

    overlay.addEventListener("mouseup", onHoge)
    overlay.addEventListener("mouseout", onHoge)

    @container.addEventListener "mousedown", (e) ->
      if e.target is container then return
      if e.which isnt 1 then return
      if option.exclude? and e.target.webkitMatchesSelector(option.exclude)
        return

      target = e.target
      while target.parentNode isnt container
        target = target.parentNode

      target.classList.add("sortable_dragging")
      document.body.appendChild(overlay)
      return
    return

do ($ = jQuery) ->
  $.fn.sortable = (option) ->
    $(@).each ->
      new UI.Sortable(@, option)
      return
    @
  return
