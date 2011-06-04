(($) ->
  $.popup = (default_parent, popup, x, y, source) ->
    $popup = $(popup)
    $popup.addClass("popup")

    $parent = $(source).closest(".popup")
    if $parent.length is 1
      $parent.append($popup)
    else
      $(default_parent).append($popup)

    $popup.css("left", "#{x + 20}px")
    $popup.css("top", "#{Math.min(y, document.body.offsetHeight - $popup.outerHeight()) - 20}px")

    remove = ->
      if $popup.find(".popup.active").length >= 1
        return

      $popup.remove()
      $(source)
        .unbind("mouseleave", start_rmtimer)
        .unbind("mouseenter", stop_rmtimer)

    rmtimer = null

    start_rmtimer = ->
      $popup.addClass("active")
      rmtimer = setTimeout(remove, 300)

    stop_rmtimer = ->
      $popup.removeClass("active")
      clearTimeout(rmtimer)
      rmtimer = null

    $popup
      .bind("mouseleave", start_rmtimer)
      .bind("mouseenter", stop_rmtimer)

    $(source)
      .bind("mouseleave", start_rmtimer)
      .bind("mouseenter", stop_rmtimer)

)(jQuery)
