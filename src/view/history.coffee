app.boot "/view/history.html", ->
  $view = $(document.documentElement)

  app.view_module.view($view)

  load = ->
    $view.addClass("loading")
    app.history.get(undefined, 500).done (data) ->
      $view.find("tbody").empty()
      frag = document.createDocumentFragment()
      for val in data
        tr = document.createElement("tr")
        tr.setAttribute("data-href", val.url)
        tr.className = "open_in_rcrx"

        td = document.createElement("td")
        td.textContent = val.title
        tr.appendChild(td)

        td = document.createElement("td")
        td.textContent = app.util.date_to_string(new Date(val.date))
        tr.appendChild(td)
        frag.appendChild(tr)
      $view.find("tbody").append(frag)
      $view.removeClass("loading")
      $view.trigger("view_loaded")
      return

  load()

  $view.on "request_reload", ->
    load()
    return

  return
