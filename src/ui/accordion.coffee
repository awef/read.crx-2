(($) ->
  $.fn.accordion = ->
    $this = $(this)
    refresh = $this.hasClass("accordion")
    $this
      .addClass("accordion")
      .find(".accordion_open")
        .removeClass("accordion_open")
      .end()
      .find("> :header:first")
        .addClass("accordion_open")
          .next()
            .show()
          .end()
      .end()
      .find("> :not(:header):not(:first)")
        .hide()

    if not refresh
      $this
        .delegate ".accordion > :header", "click", ->
          $(this)
            .toggleClass("accordion_open")
            .next()
              .slideToggle(250)
            .end()
            .siblings(".accordion_open")
              .removeClass("accordion_open")
              .next()
                .slideUp(250)
          return
    this
)(jQuery)
