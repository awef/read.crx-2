(($) ->
  $.fn.table_sort = (method = "init", config = {}) ->
    switch method
      when "init"
        $(@)
          .addClass("table_sort")
          .find("th")
            .on "click", ->
              $th = $(@)
              sort_order = if $th.hasClass("table_sort_desc") then "asc" else "desc"
              $th
                .siblings()
                  .andSelf()
                    .removeClass("table_sort_asc table_sort_desc")
              $th.addClass("table_sort_#{sort_order}")
              $th.closest("table").table_sort("update")
              return

      when "update"
        {sort_index, sort_type, sort_order} = config

        $this = $(@)
        table = @[0]

        table.style["display"] = "none"

        if sort_index? and sort_order?
          $th = (
            $this
              .find("th")
                .removeClass("table_sort_asc table_sort_desc")
                .filter("th:nth-child(#{sort_index + 1})")
          )
          $th.addClass("table_sort_#{sort_order}")
          unless sort_type?
            sort_type = $th.attr("data-table_sort_type", sort_type)
        else
          $th = $this.find(".table_sort_asc, .table_sort_desc")
          return if $th.length isnt 1
          sort_index = $th.index()
          sort_order = if $th.hasClass("table_sort_asc") then "asc" else "desc"
        sort_type ?= $th.attr("data-table_sort_type") or "str"

        tbody = table.querySelector("tbody")

        data = {}
        for td in tbody.querySelectorAll("td:nth-child(#{sort_index + 1})")
          data[td.textContent] or= []
          data[td.textContent].push(td.parentNode)

        data_keys = Object.keys(data)
        if sort_type is "num"
          data_keys.sort((a, b) -> a - b)
        else
          data_keys.sort()

        if sort_order is "desc"
          data_keys.reverse()

        for key in data_keys
          for tr in data[key]
            tbody.insertBefore(tr)

        table.style["display"] = "table"

        $this.trigger("table_sort_updated")
    @
)(jQuery)
