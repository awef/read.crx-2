app.boot "/view/config.html", ->
  $view = $(document.documentElement)

  app.view_module.view($view)

  #閉じるボタン
  $view.find(".button_close").bind "click", ->
    if frameElement
      tmp = type: "request_killme"
      parent.postMessage(JSON.stringify(tmp), location.origin)
    return

  #汎用設定項目
  $view
    .find("input.direct[type=\"text\"]")
      .each ->
        this.value = app.config.get(this.name) or ""
        null
      .bind "input", ->
        app.config.set(this.name, this.value)
        return

  $view
    .find("input.direct[type=\"checkbox\"]")
      .each ->
        this.checked = app.config.get(this.name) is "on"
        null
      .bind "change", ->
        app.config.set(this.name, if this.checked then "on" else "off")
        return

  $view
    .find("input.direct[type=\"radio\"]")
      .each ->
        if this.value is app.config.get(this.name)
          this.checked = true
        return
      .bind "change", ->
        val = $view.find("""input[name="#{this.name}"]:checked""").val()
        app.config.set(this.name, val)
        return

  #バージョン情報表示
  $view.find(".version_info")
    .text("#{app.manifest.name} v#{app.manifest.version} + #{navigator.userAgent}")

  #忍法帖関連機能
  (->
    fn = (res, $ul) ->
      if res.length is 0
        $ul.remove()
      else
        frag = document.createDocumentFragment()

        for info in res
          li = document.createElement("li")
          li.setAttribute("data-site_id", info.site.site_id)

          div = document.createElement("div")
          div.textContent = "#{info.site.site_name} : #{info.value}"
          li.appendChild(div)

          button = document.createElement("button")
          button.type = "button"
          button.textContent = "削除"
          button.className = "del_ninja_cookie"
          li.appendChild(button)

          frag.appendChild(li)

        $ul.append(frag)

    app.ninja.get_cookie().done (res) ->
      fn(res, $view.find(".ninja_cookie_info"))

    $view.delegate ".del_ninja_cookie", "click", ->
      $this = $(@)
      $.dialog("confirm",
          message: "本当に削除しますか？",
          label_ok: "はい",
          label_no: "いいえ"
        )
        .done (result) ->
          if result
            $this
              .attr("disabled", true)
              .text("削除中")
            site_id = $this.parent().attr("data-site_id")
            app.ninja.delete_cookie(site_id)
              .done ->
                $this.parent().fadeOut ->
                  $this = $(@)
                  $parent = $this.parent()
                  $this.remove()
                  if $parent.children().length is 0
                    $parent.remove()
  )()

  #板覧更新ボタン
  $view.find(".bbsmenu_reload").bind "click", ->
    $button = $(this)
    $status = $view.find(".bbsmenu_reload_status")

    $button.attr("disabled", true)
    $status
      .removeClass("done fail")
      .addClass("loading")
      .text("更新中")

    app.bbsmenu.get (res) ->
      $button.removeAttr("disabled")
      $status.removeClass("loading")
      if res.status is "success"
        $status
          .addClass("done")
          .text("更新完了")

        iframe = parent.document.querySelector("iframe[src^=\"/view/sidemenu.html\"]")
        if iframe
          tmp = JSON.stringify(type: "request_reload")
          iframe.contentWindow.postMessage(tmp, location.origin)

        #TODO [board_title_solver]も更新するよう変更
      else
        $status
          .addClass("fail")
          .text("更新失敗")
    , true

    return

  #履歴
  (->
    $clear_button = $view.find(".history_clear")
    $status = $view.find(".history_status")

    #履歴件数表示
    app.history.get_count().done (count) ->
      $status.text("#{count}件")

    #履歴削除ボタン
    $clear_button.on "click", ->
      $clear_button.remove()
      $status.text("削除中")

      $.when(app.history.clear(), app.read_state.clear())
        .done ->
          $status.text("削除完了")
          parent.$("iframe[src=\"/view/history.html\"]").each ->
            @contentWindow.$(".view").trigger("request_reload")
        .fail ->
          $status.text("削除失敗")
      return
  )()

  #キャッシュ削除ボタン
  $view.find(".cache_clear").bind "click", ->
    $button = $(this)
    $status = $view.find(".cache_clear_status")

    $button.attr("disabled", true)
    $status.text("削除中")

    app.cache.clear()
      .always ->
        $button.removeAttr("disabled")
      .done ->
        $status.text("削除完了")
      .fail ->
        $status.text("削除失敗")
    return

  #ブックマークフォルダ変更ボタン
  $view.find(".bookmark_source_change").bind "click", ->
    app.message.send("open", url: "bookmark_source_selector")
    return

