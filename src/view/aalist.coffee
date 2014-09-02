app.boot "/view/aalist.html", ->
  $view = $(document.documentElement)

  new app.view.TabContentView(document.documentElement)

  $table = $("<table>")
  $table.attr("id", "aatable")
  $table.appendTo(".content")
  $th = $("<tr>")
    .append("<th>タイトル</th>")
    .append("<th>更新日時</th>")
  $table.append($("<thead>").append($th))
  
  $tbody = $("<tbody>")
  $table.append($tbody)

  load = ->
    return if $view.hasClass("loading")
    return if $view.find(".button_reload").hasClass("disabled")

    $view.addClass("loading")

    app.AA.getList(undefined, undefined).done (data) ->
      $("table#aatable tbody *").remove()
      for item in data
        dateobj = new Date(item.date)
        datestr = dateobj.getFullYear() + "/" +
          ("0" + (dateobj.getMonth() + 1)).slice(-2) + "/" +
          ("0" + dateobj.getDay()).slice(-2) + " " +
          ("0" + dateobj.getHours()).slice(-2) + ":" +
          ("0" + dateobj.getMinutes()).slice(-2)

        $tr = $("<tr>")
          .append("<td>#{item.title}</td>")
          .append("<td>#{datestr}</td>")
          .data("id", item.id)
        $tbody.append($tr)

      $("table#aatable td").on("click", ->
        app.AA.openEditPopup($.data($(this).parent()[0], "id"))
        return
      )

      app.message.add_listener "reload_aalist", (message) -> load()

      $view.removeClass("loading")
      $view.trigger("view_loaded")
      return
    return

  $view.on("request_reload", load)
  load()

  $view.find(".button_add_aa").on "click", ->
    app.AA.openEditPopup()
    return
  return
