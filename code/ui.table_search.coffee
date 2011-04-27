(($) ->
  $.fn.table_search = (method, prop) ->
    $table = $(this)
    $table
      .hide()
      .removeAttr("data-table_search_hit_count")
      .find(".table_search_hit")
        .removeClass("table_search_hit")

    # prop.query, prop.search_col
    if method is "search"
      $table.addClass("table_search")
      hit_count = 0
      for tr in $table.find("tbody")[0].children
        td = tr.children[prop.target_col]
        if td.innerText.toLowerCase().indexOf(prop.query) isnt -1
          tr.classList.add("table_search_hit")
          hit_count++
      $table.attr("data-table_search_hit_count", hit_count)
    else if method is "clear"
      $table.removeClass("table_search")

    $table.show()
    this
)(jQuery)
