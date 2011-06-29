(($) ->
  $.popup = (default_parent, popup, x, y, source) ->
    $popup = $(popup)
    $popup
      .addClass("popup")
      .data("popup_source", source)

    #.popup内にsourceが有った場合はネスト
    #そうでなければ、指定されたデフォルトの要素に追加
    $parent = $(source).closest(".popup")
    if $parent.length is 1
      $parent.append($popup)
    else
      $(default_parent).append($popup)

    #同一ソースからのポップアップが既に有る場合は、処理を中断
    flg = false
    $popup.siblings(".popup").each ->
      flg or= $($(this).data("popup_source")).is(source)
      null
    if flg
      $popup.remove()
      return

    #同一ソースからのポップアップがネストしないよう処理
    if tmp = $popup.parent(".popup").data("popup_source")
      if $(tmp).html() is $(source).html()
        $popup.remove()
        return

    #画面内に収まるよう、表示位置を修正
    if x < document.body.offsetWidth / 5 * 3
      $popup.css("left", "#{x + 20}px")
    else
      $popup.css("right", "#{document.body.offsetWidth - x + 20}px")
    $popup.css("top", "#{Math.min(y, document.body.offsetHeight - $popup.outerHeight()) - 20}px")

    #ポップアップ削除関連の処理
    remove = ->
      if $popup.find(".popup.active").length >= 1
        return

      $popup.remove()
      $(source)
        .unbind("mouseleave", start_rmtimer)
        .unbind("mouseenter", stop_rmtimer)

    rmtimer = null

    start_rmtimer = ->
      $popup.addClass("active")
      rmtimer = setTimeout(remove, 300)

    stop_rmtimer = ->
      $popup.removeClass("active")
      clearTimeout(rmtimer)
      rmtimer = null

    $popup
      .bind("mouseleave", start_rmtimer)
      .bind("mouseenter", stop_rmtimer)

    $(source)
      .bind("mouseleave", start_rmtimer)
      .bind("mouseenter", stop_rmtimer)

)(jQuery)
