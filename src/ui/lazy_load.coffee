(($) ->
  load = (img) ->
    new_img = document.createElement("img")
    $(new_img).one "load error", (e) ->
      img.parentNode.replaceChild(new_img, img)
      if e.type is "load"
        $(@)
          .trigger("lazy_load_complete")
          .hide()
          .fadeIn()
      return
    new_img.src = img.getAttribute("data-href")

  $.fn.lazy_load = ({container}) ->
    container = $(container)[0]
    imgs = Array::slice.apply(@)

    if imgs.length isnt 0
      do ->
        scroll_flg = false
        listener = -> scroll_flg = true; return
        $(container).on("scroll", listener)
        interval = setInterval(->
            if scroll_flg
              imgs = imgs.filter (img) ->
                top = 0
                current = img
                while current isnt null and current isnt container
                  top += current.offsetTop
                  current = current.offsetParent
                unless (top + img.offsetHeight < container.scrollTop or
                    container.scrollTop + container.clientHeight < top)
                  load(img)
                  return false
                true

              if imgs.length is 0
                clearInterval(interval)
                $(container).off("scroll", listener)
          , 200)

    return @
)(jQuery)
