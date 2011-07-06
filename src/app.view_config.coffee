app.view_config = {}

app.view_config.open = ->
  $view = $("#template > .view_config").clone()

  #汎用設定項目
  $view
    .find("input.direct[type=\"text\"]")
      .each ->
        this.value = app.config.get(this.name) or ""
        null
      .bind "input", ->
        app.config.set(this.name, this.value)

  $view
    .find("input.direct[type=\"checkbox\"]")
      .each ->
        this.checked = app.config.get(this.name) is "on"
        null
      .bind "change", ->
        app.config.set(this.name, if this.checked then "on" else "off")

  $view
    .find("input.direct[type=\"radio\"]")
      .each ->
        if this.value is app.config.get(this.name)
          this.checked = true
        return
      .bind "change", ->
        val = $view.find("""input[name="#{this.name}"]:checked""").val()
        app.config.set(this.name, val)

  #バージョン情報表示
  $view.find(".version_info")
    .text("#{app.manifest.name} v#{app.manifest.version} + #{navigator.userAgent}")

  #忍法帖関連機能
  ###
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
  ###

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

        $(".view_sidemenu").trigger("request_reload")
        #TODO [board_title_solver]も更新するよう変更
      else
        $status
          .addClass("fail")
          .text("更新失敗")
    , true

  #履歴削除ボタン
  $view.find(".history_clear").bind "click", ->
    $button = $(this)
    $status = $view.find(".history_clear_status")

    $button.attr("disabled", true)
    $status.text("削除中")

    $.when(app.history.clear(), app.read_state.clear())
      .always ->
        $button.removeAttr("disabled")
      .done ->
        $status.text("削除完了")
        $(".view_history").trigger("request_reload")
      .fail ->
        $status.text("削除失敗")

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

  #ブックマークフォルダ変更ボタン
  $view.find(".bookmark_source_change").bind "click", ->
    app.view_bookmark_source_selector.open()

  $view
