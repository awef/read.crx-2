(($) ->
  $.fn.sortable = ->
    $(this)
      .addClass("sortable")

      .delegate ".sortable > *", "dragstart", ->
        $(this).addClass("sortable_dragging")

      .delegate ".sortable > *", "dragend", ->
        $(this).removeClass("sortable_dragging")

      .delegate ".sortable > *", "dragenter", ->
        $this = $(this)
        $target = $this.siblings(".sortable_dragging")
        if not $this.is($target)
          $target[if $target.index() < $this.index() then "insertAfter" else "insertBefore"]($this)

      .delegate ".sortable > *", "dragenter dragover", (e) ->
        e.preventDefault()

      .delegate ".sortable > *:not([draggable])", "mousedown", ->
        $(this).attr("draggable", true)

    this
)(jQuery)
