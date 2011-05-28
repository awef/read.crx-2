(($) ->
  $.fn.table_sort = ->
    $(this)
      .find("th")
      .bind "click", ->
        $th = $(this)
        $table = $th.closest("table")
        $table.hide()
        tbody = $table.find("tbody")[0]

        sort_index = $th.index()
        sort_type = $th.data("table_sort_type") or "str"
        sort_order = if $th.hasClass("table_sort_desc") then "asc" else "desc"

        $th
          .siblings()
            .andSelf()
              .removeClass("table_sort_asc table_sort_desc")
        $th.addClass("table_sort_#{sort_order}")

        data = {}
        for td in tbody.querySelectorAll("td:nth-child(#{sort_index + 1})")
          data[td.textContent] or= []
          data[td.textContent].push(td.parentNode)

        data_keys = Object.keys(data)
        if sort_type is "num"
          data_keys.sort((a, b) -> return a - b)
        else
          data_keys.sort()

        if sort_order is "desc"
          data_keys.reverse()

        for key in data_keys
          for tr in data[key]
            tbody.insertBefore(tr)

        $table.show()

      this
)(jQuery)
