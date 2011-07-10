# #app.view_tab_state
# タブの状態の保存/復元を行う
app.view_tab_state = {}

app.view_tab_state._get = ->
  data = []

  tmp = Array::slice.apply(document.getElementsByClassName("tab_content"))

  for tab_content in tmp
    tab_url = tab_content.getAttribute("data-url")
    tab_title = tab_content.getAttribute("data-title")

    data.push
      url: tab_url
      title: tab_title

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
