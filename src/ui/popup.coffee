(($) ->
  $.popup = (popup, x, y, source) ->
    $popup = $(popup)
    $popup.addClass("popup")

    $popup.css("left", "#{x + 20}px")
    $popup.css("top", "#{Math.min(y, document.body.offsetHeight - $popup.outerHeight()) - 20}px")

    $(source).one "mouseleave", ->
      $popup.remove()
)(jQuery)
