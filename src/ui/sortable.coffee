(($) ->
  $.fn.sortable = ->
    $(this)
      .addClass("sortable")

      .delegate "> *", "dragstart", ->
        $(this).addClass("sortable_dragging")
        return

      .delegate "> *", "dragend", ->
        $(this).removeClass("sortable_dragging")
        return

      .delegate "> *", "dragenter", ->
        $this = $(this)
        $target = $this.siblings(".sortable_dragging")
        if not $this.is($target)
          $target[if $target.index() < $this.index() then "insertAfter" else "insertBefore"]($this)
        return

      .delegate "> *", "dragenter dragover", (e) ->
        e.preventDefault()
        return

      .delegate "> *:not([draggable])", "mousedown", ->
        $(this).attr("draggable", true)
        return

    this
)(jQuery)
