do ($ = jQuery) ->
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
    return

  $.fn.lazy_load = ({container}) ->
    container = $(container)[0]

    do (imgs = Array::slice.apply(@)) ->
      return if imgs.length is 0

      scroll_flg = false
      listener = -> scroll_flg = true; return
      $(container).on("scroll", listener)
      interval = setInterval(->
        if scroll_flg
          scroll_flg = false

          imgs = imgs.filter (img) ->
            # imgが非表示の時はロードしない
            if img.offsetWidth is 0
              return true

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
      return
    @
  return
