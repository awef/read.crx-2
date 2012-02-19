module "Content Security Policy"

test "同一オリジンからのスクリプトのロードは可能", 1, ->
  #このテストが実行出来ている時点で、この項目は満たされている
  ok(true)

asyncTest "別オリジンからのスクリプトのロードは許可されない", 1, ->
  script = document.createElement("script")
  script.src = "https://www.google.com/jsapi"
  script.addEventListener "error", ->
    ok(true, "https://www.google.com")
    start()
  script.addEventListener "load", ->
    ok(false)
    start()
  document.querySelector("#qunit-fixture").appendChild(script)

asyncTest "別オリジンからのスクリプトのロードは許可されない 2", 1, ->
  script = document.createElement("script")
  script.src = "data:text/plain,alert();"
  script.addEventListener "error", ->
    ok(true, "data:")
    start()
  script.addEventListener "load", ->
    ok(false)
    start()
  document.querySelector("#qunit-fixture").appendChild(script)

test "インラインスクリプトは拒否される", 1, ->
  script = document.createElement("script")
  script.innerHTML = """ window.csp_test = true; """
  document.querySelector("#qunit-fixture").appendChild(script)
  ok(not window.csp_test?)
  delete window.csp_test

test "A要素のhrefにJavaScriptスキームのURLを指定しても動作しない", 1, ->
  a = document.createElement("a")
  a.href = "javascript:void(window.csp_test = true);"
  document.querySelector("#qunit-fixture").appendChild(a)
  e = document.createEvent("MouseEvents")
  e.initMouseEvent("click")
  a.dispatchEvent(e)
  ok(not window.csp_test?)
  delete window.csp_test

test "インラインのイベントハンドラは動作しない", 1, ->
  span = document.createElement("span")
  span.setAttribute("onclick", "window.csp_test = true;")
  document.querySelector("#qunit-fixture").appendChild(span)
  e = document.createEvent("MouseEvents")
  e.initMouseEvent("click")
  span.dispatchEvent(e)
  ok(not window.csp_test?, "todo")
  delete window.csp_test

asyncTest "Data URI schemeによる画像の読み込みが可能", 1, ->
  img = document.createElement("img")
  img.addEventListener "load", ->
    ok(true)
    start()
    return
  img.src = "data:image/gif;base64,R0lGODlhAQABAPAAAP///wAAACH5BAAAAAAALAAAAAABAAEAAAICRAEAOw=="
  document.querySelector("#qunit-fixture").appendChild(img)
  return
