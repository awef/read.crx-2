(($)->
  $.fn.lazy_img = ->
    $(this).each ->
      img_list = Array::slice.apply(
        this.querySelectorAll("[data-lazy_img_original_path]")
      )

      scroll_flg = false
      interval = setInterval =>
        if scroll_flg
          img_list.forEach (img, key) =>
            unless img.offsetTop + img.offsetHeight < this.scrollTop or
                this.scrollTop + this.offsetHeight < img.offsetTop
              img_list.splice(key, 1)
              img.src = img.getAttribute("data-lazy_img_original_path")
              img.removeAttribute("data-lazy_img_original_path")

          scroll_flg = false
      , 200

      on_scroll = ->
        scroll_flg = true

      $(this)
        .bind("scroll", on_scroll)
        .one "lazy_img_destroy", ->
          $(this).unbind("scroll", on_scroll)
          clearInterval(interval)
      null
    this
)(jQuery)
