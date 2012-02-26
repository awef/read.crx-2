(($) ->
  uid = do ->
    count = 0
    -> "tab_id" + (++count)

  tab_init = ->
    that = this
    $(this)
      .addClass("tab")
      .append('<ul class="tab_tabbar">', '<div class="tab_container">')
      .delegate ".tab_tabbar", "mousewheel", (e) ->
        e.preventDefault()
        tmp = if e.originalEvent.wheelDelta > 0 then "previousSibling" else "nextSibling"
        next = that.querySelector(".tab_tabbar li.tab_selected")?[tmp]

        if next
          tab_select.call(that, {tab_id: next.getAttribute("data-tab_id")})
        return

      .on "mousedown", ".tab_tabbar > li", (e) ->
        if $(e.target).is(".tab_tabbar > li > img") then return
        (if e.which is 2 then tab_remove else tab_select)
          .call(that, {tab_id: $(@).attr("data-tab_id")})
        return

      .delegate ".tab_tabbar img", "mousedown", (e) ->
        e.preventDefault()
        return

      .delegate ".tab_tabbar img", "click", ->
        tab_remove.call(that, tab_id: $(this).parent().attr("data-tab_id"))
        return

  # prop.element, prop.title, [prop.background], [prop.new_tab]
  tab_add = (prop) ->
    $tab = $(this)
    tab_id = uid()

    if prop.new_tab isnt true
      $li = $tab.find("li.tab_selected").empty()
      $tab
        .find(".tab_content[data-tab_id=\"#{$li.attr("data-tab_id")}\"]")
          .trigger("tab_removed")
          .remove()
    if not $li? or $li.length is 0
      $li = $("<li>").appendTo($tab.find(".tab_tabbar"))

    $li
      .attr("data-tab_id": tab_id, title: prop.title)
      .append($("<span>", {text: prop.title}))
      .append($("<img>", {src: "/img/close_16x16.png", title: "閉じる"}))

    $(prop.element)
      .addClass("tab_content")
      .attr("data-tab_id", tab_id)
      .appendTo($tab.find(".tab_container"))

    unless prop.background and $tab.find(".tab_tabbar li").length isnt 1
      tab_select.call(this, {tab_id: tab_id})

  # prop.tab_id
  tab_remove = (prop) ->
    that = this
    $tab = $(this)

    $tab
      .find("[data-tab_id=\"#{prop.tab_id}\"]")
        .filter(".tab_tabbar li.tab_selected")
          .each(->
            $this = $(this)

            next = $this.prev("li").add($this.next("li"))
            if next.length
              tab_select.call(that, {tab_id: next.attr("data-tab_id")})
            null
          )
        .end()
        .filter(".tab_content")
          .trigger("tab_removed")
        .end()
      .remove()

  # prop.tab_id
  tab_select = (prop) ->
    for tmp in Array::slice.apply(this.getElementsByClassName("tab_selected"))
      tmp.classList.remove("tab_selected")

    for tmp in this.querySelectorAll("[data-tab_id=\"#{prop.tab_id}\"]")
      tmp.classList.add("tab_selected")
      if tmp.classList.contains("tab_content")
        $(tmp).trigger("tab_selected")

    return

  # prop.tab_id, prop.title
  tab_update_title = (prop) ->
    $(this)
      .find("[data-tab_id=\"#{prop.tab_id}\"]")
        .filter(".tab_tabbar > li")
          .attr("title", prop.title)
          .find("span")
            .text(prop.title)
          .end()
        .end()
        .filter(".tab_content")
          .attr("data-title", prop.title)

  $.fn.tab = (method, prop) ->
    $(this)
      .each((key, val) ->
        (
          init: tab_init
          add: tab_add
          remove: tab_remove
          select: tab_select
          update_title: tab_update_title
        )[method or "init"].call(val, prop or {})
        null
      )
    this
)(jQuery)
