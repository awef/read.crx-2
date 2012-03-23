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
        {sort_index, sort_attribute, sort_type, sort_order} = config

        $this = $(@)
        table = @[0]

        event = $.Event("table_sort_before_update")
        $this.trigger(event)
        if event.isDefaultPrevented()
          return

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
            sort_type = $th.attr("data-table_sort_type")
        else if not sort_attribute?
          $th = $this.find(".table_sort_asc, .table_sort_desc")
          if $th.length isnt 1
            table.style["display"] = "table"
            return
          sort_index = $th.index()
          sort_order = if $th.hasClass("table_sort_asc") then "asc" else "desc"

        tbody = table.querySelector("tbody")

        if sort_index?
          sort_type ?= $th.attr("data-table_sort_type") or "str"
          data = {}
          for td in tbody.querySelectorAll("td:nth-child(#{sort_index + 1})")
            data[td.textContent] or= []
            data[td.textContent].push(td.parentNode)
        else if sort_attribute?
          $this.find("th").removeClass("table_sort_asc table_sort_desc")
          sort_type ?= "str"
          data = {}
          for tr in tbody.getElementsByTagName("tr")
            value = tr.getAttribute(sort_attribute)
            data[value] or= []
            data[value].push(tr)

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

        exparam = {sort_order, sort_type}
        if sort_index?
          exparam.sort_index = sort_index
        else
          exparam.sort_attribute = sort_attribute

        $this.trigger("table_sort_updated", exparam)
    @
)(jQuery)
