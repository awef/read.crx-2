app.view.config = {}

app.view.config.open = ->
  $view = $("#template > .view_config").clone()

  $view
    .find("input.direct[type=\"text\"]")
      .each ->
        this.value = app.config.get(this.name) or ""
      .bind "input", ->
        app.config.set(this.name, this.value)

  $view.find(".version_info")
    .text("#{app.manifest.name} v#{app.manifest.version} + #{navigator.userAgent}")

  fn = (res, $ul) ->
    if res.length is 0
      $ul.remove()
    else
      $ul.next().remove()
      frag = document.createDocumentFragment()

      text = ""
      for info in res
        li = document.createElement("li")
        li.textContent = "#{info.site.site_name} : #{info.value}\n"
        frag.appendChild(li)

      $ul.append(frag)

  app.ninja.get_info_cookie().done (res) ->
    fn(res, $view.find(".ninja_info_cookie"))

  app.ninja.get_info_stored().done (res) ->
    fn(res, $view.find(".ninja_info_stored"))

  $("#tab_a").tab("add", element: $view[0], title: "設定")
