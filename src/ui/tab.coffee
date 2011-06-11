(($) ->
  uid = (->
    count = 0
    -> "tab_id" + (++count)
  )()

  tab_init = ->
    that = this
    $(this)
      .addClass("tab")
      .append('<ul class="tab_tabbar">', '<div class="tab_container">')
      .delegate ".tab_tabbar", "mousewheel", (e) ->
        e.preventDefault()
        way = if e.wheelDelta > 0 then "prev" else "next"
        next = $(that).find(".tab_tabbar li.tab_selected")[way]()

        if next.length is 1
          tab_select.call(that, {tab_id: next.attr("data-tab_id")})

      .delegate ".tab_tabbar li", "mousedown", (e) ->
        (if e.which is 2 then tab_remove else tab_select)
          .call(that, {tab_id: $(this).attr("data-tab_id")})

      .delegate ".tab_tabbar img", "click", ->
        tab_remove.call(that, tab_id: $(this).parent().attr("data-tab_id"))

  # prop.element, prop.title, [prop.background]
  tab_add = (prop) ->
    $tab = $(this)
    tab_id = uid()

    $("<li>", {"data-tab_id": tab_id, title: prop.title})
      .append($("<span>", {text: prop.title}))
      .append($("<img>", {src: "/img/close_16x16.png", title: "閉じる"}))
      .appendTo($tab.find(".tab_tabbar"))

    $(prop.element)
      .addClass("tab_content")
      .attr("data-tab_id", tab_id)
      .appendTo($tab.find(".tab_container"))
      .bind "click", ->
        if not this.classList.contains("tab_focused")
          $(".tab_focused").removeClass("tab_focused")
          $tab.find("[data-tab_id=\"#{tab_id}\"]").addClass("tab_focused")

    unless prop.background and $this.find(".tab_tabbar li").length isnt 1
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
          )
        .end()
        .filter(".tab_container > *")
          .trigger("tab_removed")
        .end()
      .remove()

    if not $tab.is(":has(.tab_focused)")
      $(".tab:has(.tab_selected):first")
        .find(".tab_selected")
          .addClass("tab_focused")

  # prop.tab_id
  tab_select = (prop) ->
    $(".tab_focused").removeClass("tab_focused")

    $(this)
      .find(".tab_selected")
        .removeClass("tab_selected")
      .end()
      .find("[data-tab_id=\"#{prop.tab_id}\"]")
        .addClass("tab_selected tab_focused")

  # prop.tab_id, prop.title
  tab_update_title = (prop) ->
    $(this)
      .find("> .tab_tabbar")
        .find("[data-tab_id=\"#{prop.tab_id}\"] span")
          .text(prop.title)
            .parent()
              .attr("title", prop.title)

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
      )
    this
)(jQuery)
