# Windows でなければTextarフォントを埋め込む
do ->
  return if /windows/i.test(navigator.userAgent)
  if "textar_font" of localStorage
    $ ->
      style = document.createElement("style")
      style.textContent = """
        @font-face {
          font-family: "Textar";
          src: url(#{localStorage.textar_font});
        }
      """
      document.head.appendChild(style)
      return
  return

app.boot "/view/editaa.html", ->
  new app.view.View(document.documentElement)
  
  # 通知するための変数
  # エラーが発生した時に通知が表示される時間(ミリ秒)
  errorNotifyTimeSpan = 4000
  # 今現在何かしら通知しているかどうか
  isNotifying = false
  # 最後に通知した時刻
  notifyDate = null

  # AAのID
  id = undefined
  # AAの最終更新時刻
  date = undefined

  # UUIDを生成する関数
  generateUUID = () ->
    x = () -> return (((1 + Math.random()) * 0x10000) | 0).toString(16).substring(1)
    return x() + x() + "-" + x() + "-" + x() + "-" + x() + "-" + x() + x() + x()
  
  # 通知をする関数
  show_notify = (text, time = null, callback = null) ->
    time = errorNotifyTimeSpan unless time?
    notifyDate = +new Date()
    $("#notify").text(text)
    window.setTimeout((d) ->
        # 与えられた時刻と最終に通知した時刻が一致していれば新たに通知がないとみなして、
        # 通知を消す。一致しなければ新たに通知があったので消さない
        $("#notify").text("") if notifyDate == d
        callback() if callback?
        return
      time
      notifyDate)
      isNotifying = true
    return

  # URIパラメタを解析する即時関数
  uriParameter = do ->
    ret = []
    eqs = window.location.href.slice(window.location.href.indexOf("?") + 1).split("&")
    for eq in eqs
      ret.push((w = eq.split('='))[0])
      try
        ret[w[0]] = decodeURIComponent(w[1])
      catch
        ret[w[0]] = "decodeURIComponent error"
    return ret

  # もしパラメタにIDがあってIDがデータベースにあれば、
  # データベースから取得して、「AAを編集」モードにする
  # そうでなければ引き続き「AAを追加」モードとなる
  if uriParameter["id"]?
    app.AA.get(uriParameter["id"]).done( (data) ->
      if data?
        $("title").text("AAを編集")
        id = data.id
        $("#title").val(data.title) unless uriParameter["title"]?
        $("#content").text(data.content) unless uriParameter["content"]?
        date = data.date
        $("#remove").removeAttr("disabled")
      else
        show_notify("ERROR: 次のAAが見つかりませんでした: #{uriParameter["id"]}"
          errorNotifyTimeSpan)
      return
    )
    .fail( () ->
      show_notify("ERROR: app.AA.get: #{uriParameter["id"]}"
        errorNotifyTimeSpan)
      return
    )
  else
    $("title").text("AAを追加")

  $("#title").val(uriParameter["title"]) if uriParameter["title"]?
  $("#content").val(uriParameter["content"]) if uriParameter["content"]?

  # 保存ボタンが押された時
  $("#save").click ->

    # 入力チェック
    if $("#content").val() == ""
      show_notify("ALERT: AA (アスキーアート)を入れてください。", errorNotifyTimeSpan)
      $("#content").focus()
      return  

    if $("#title").val() == "" 
      show_notify("タイトルを入れることで後で探しやすくなります。" +
        "このタイトルで良ければもう一度「保存」ボタンをクリックしてください。",
        errorNotifyTimeSpan)
      $("#title").val(String(new Date()) + " に追加したAA")
      $("#title").focus()
      return

    date = +new Date()
    
    # idがあればupdate, なければidを生成してadd
    if id?
      app.AA.update(id, $("#title").val(), $("#content").val(), date).done(()->
        # TODO: aalist.htmlを更新するよう要求
        window.close()
        return
      ).fail(() ->
        show_notify("更新失敗: #{id}", errorNotifyTimeSpan)
        return
      )
    else
      id = generateUUID()
      app.AA.add(id, $("#title").val(), $("#content").val(), date).done(()->
        # TODO: aalist.htmlを更新するよう要求
        window.close()
        return
      ).fail(() ->
        show_notify("新規保存失敗: #{id}", errorNotifyTimeSpan)
        return
      )
    return


  # 削除ボタン
  $("#remove").click ->
    if id?
      app.AA.remove(id).done( () ->
        # TODO: aalist.htmlを更新するよう要求
        window.close()
        return
      )
      .fail( () ->
        show_notify("ERROR: 削除に失敗しました。", errorNotifyTimeSpan)
        return
      )
    else
      show_notify("ALERT: まだ保存されていません", errorNotifyTimeSpan)
    return


  $("#cancel").click -> window.close()

  $("#copy").click ->
    app.clipboardWrite($("#content").text()) if $("#content").text().length > 0
    window.close()
  return

