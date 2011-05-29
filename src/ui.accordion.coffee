(($) ->
  $.fn.accordion = ->
    $(this)
      .addClass("accordion")
      .find("> :header:first")
        .addClass("accordion_open")
      .end()
      .find("> :not(:header):not(:first)")
        .hide()
      .end()
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
    this
)(jQuery)
