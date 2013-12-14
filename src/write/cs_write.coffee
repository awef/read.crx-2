do ->
  origin = chrome.extension.getURL("").slice(0, -1)

  exec = (javascript) ->
    script = document.createElement("script")
    script.innerHTML = javascript
    document.body.appendChild(script)

  send_message_ping = ->
    exec """
      parent.postMessage(JSON.stringify({type : "ping"}), "#{origin}");
    """

  send_message_success = ->
    exec """
      parent.postMessage(JSON.stringify({type : "success"}), "#{origin}");
    """

  send_message_confirm = ->
    exec """
      parent.postMessage(JSON.stringify({type : "confirm"}), "#{origin}");
    """

  send_message_error = (message) ->
    if typeof message is "string"
      exec """
        parent.postMessage(JSON.stringify({
          type: "error",
          message: "#{message.replace(/\"/g, "&quot;")}"
        }), "#{origin}");
      """
    else
      exec """
        parent.postMessage(JSON.stringify({type : "error"}), "#{origin}");
      """

  main = ->
    #2ch投稿確認
    if ///^http://\w+\.2ch\.net/test/bbs\.cgi///.test(location.href)
      if /書きこみました/.test(document.title)
        send_message_success()
      else if /確認/.test(document.title)
        setTimeout(send_message_confirm , 1000 * 6)
      else if /ＥＲＲＯＲ/.test(document.title)
        send_message_error()

    #したらば投稿確認
    else if ///^http://jbbs\.shitaraba\.net/bbs/write.cgi/\w+/\d+/\d+/$///.test(location.href)
      if /書きこみました/.test(document.title)
        send_message_success()
      else if /ERROR/.test(document.title)
        send_message_error()

    #p2
    else if ///^http://w\d+\.p2\.2ch\.net/p2/post_form\.php///.test(location.href)
      if form = document.getElementById("resform")
        arg = app.url.parse_query(location.href)

        if arg.expected_url isnt location.href.slice(0, arg.expected_url.length)
          send_message_error("error: unexpected url")
          return

        form.FROM.value = arg.rcrx_name
        form.mail.value = arg.rcrx_mail
        form.MESSAGE.value = arg.rcrx_message
        form.__proto__.submit.call(form)

      else
        send_message_error("p2にログインしていません。ログインしていてもこのメッセージが出る場合、p2サーバーの設定が間違っている可能性が有ります。その場合はオプションページから修正して下さい。")

    else if ///^http://w\d+\.p2\.2ch\.net/p2/post\.php///.test(location.href)
      if /書きこみました/.test(document.title)
        send_message_success()
      else if document.querySelector("meta[http-equiv=\"refresh\"]")
        send_message_error(document.body.innerText)
        location.href = "about:blank"
      else
        send_message_error()

  boot = ->
    window.addEventListener "message", (e) ->
      if e.origin is origin and e.data is "write_iframe_pong"
        main()
      return

    send_message_ping()

  setTimeout(boot, 0)
