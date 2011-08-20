(($) ->
  $root = null

  popup_destroy = ($popup) ->
    $popup.find(".popup").andSelf()
      .each ->
        $($(@).data("popup_source"))
          .unbind("mouseleave", on_mouseenter)
          .unbind("mouseenter", on_mouseleave)
    $popup.remove()

  remove = ->
    return unless $root
    $root.find(".popup").andSelf().filter(":not(.active)")
      .each ->
        $this = $(@)
        if $this.has(".popup.active").length is 0
          $root = null if $this.is($root)
          popup_destroy($this)

  on_mouseenter = ->
    $this = $(@)
    $popup = if $this.is(".popup") then $this else $($this.data("popup"))
    $popup.addClass("active")
    return

  on_mouseleave = ->
    $this = $(@)
    $popup = if $this.is(".popup") then $this else $($this.data("popup"))
    $popup.removeClass("active")
    setTimeout(remove, 300)
    return

  $(document.documentElement).bind "mousewheel", (e) ->
    if $root
      popup_destroy($root)
      $root = null
    return

  $.popup = (default_parent, popup, x, y, source) ->
    $popup = $(popup)
    $popup
      .addClass("popup active")
      .data("popup_source", source)

    #.popup内にsourceが有った場合はネスト
    #そうでなければ、指定されたデフォルトの要素に追加
    $parent = $(source).closest(".popup")
    if $parent.length is 1
      $parent.append($popup)
    else
      popup_destroy($root) if $root
      $root = $popup
      $(default_parent).append($popup)

    #同一ソースからのポップアップが既に有る場合は、処理を中断
    flg = false
    $popup.siblings(".popup").each ->
      flg or= $($(this).data("popup_source")).is(source)
      null
    if flg
      $popup.remove()
      return

    #兄弟ノードの削除
    $parent.children(".popup").each ->
      if not ($this = $(@)).is($popup)
        popup_destroy($this)

    #画面内に収まるよう、表示位置を修正
    if x < document.body.offsetWidth / 5 * 3
      left = x + 20
      $popup.css("left", "#{left}px")
      $popup.css("max-width", document.body.offsetWidth - left - 20)
    else
      right = document.body.offsetWidth - x + 20
      $popup.css("right", "#{right}px")
      $popup.css("max-width", document.body.offsetWidth - right - 20)
    $popup.css("top", "#{Math.min(y, document.body.offsetHeight - $popup.outerHeight()) - 20}px")

    $(source)
      .data("popup", $popup[0])
      .add($popup)
        .bind("mouseenter", on_mouseenter)
        .bind("mouseleave", on_mouseleave)

)(jQuery)

