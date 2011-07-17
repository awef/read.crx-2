if location.hash is "#rcrx"
  document.documentElement.addEventListener "click", (e) ->
    if e.target.nodeName is "A"
      a = e.target

      type = app.url.guess_type(a.href).type
      #read.crxで開ける形式のリンクがクリックされた場合
      if type is "thread" or type is "board"
        e.preventDefault()
        url = chrome.extension.getURL("app.html")
        url += "?q=#{encodeURIComponent(a.href)}"
        open(url)
      #find.2ch.net内の別のページに飛んだ場合
      else if a.host is "find.2ch.net" and a.hash is ""
        a.hash = "rcrx"
    return

