# #app.view_tab_state
# タブの状態の保存/復元を行う
app.view_tab_state = {}

app.view_tab_state._get = ->
  data = []
  $(".tab .tab_tabbar li").each (key, val) ->
    tab_id = val.getAttribute("data-tab_id")
    url = (
      val
        .parentNode
          .parentNode
            .querySelector(".tab_container [data-tab_id=\"#{tab_id}\"]")
              .getAttribute("data-url")
    )
    data.push
      title: val.title
      url: url
    null
  data

# ##app.view_tab_state.store
# 現在の全てのタブのURLとタイトルを保存  
# unload時に使用出来るよう、非同期処理は用いてはいけない
app.view_tab_state.store = ->
  localStorage["tab_state"] = JSON.stringify(app.view_tab_state._get())

# ##app.view_tab_state.restore
# 保存されていたタブを復元
app.view_tab_state.restore = ->
  is_restored = false

  if localStorage["tab_state"]
    for tab in JSON.parse(localStorage["tab_state"])
      is_restored = true
      app.message.send("open", url: tab.url)

  is_restored
