app = {}

(->
  origin = chrome.extension.getURL("").slice(0, -1)

  exec = (javascript) ->
    script = document.createElement("script")
    script.innerHTML = javascript
    document.body.appendChild(script)

  main = ->
    if ///^http://\w+\.2ch\.net/test/read\.cgi/\w+/\d+/1\?///.test(location.href)
      form = document.createElement("form")
      form.action = "/test/bbs.cgi"
      form.method = "POST"

      form_data =
        submit: "書きこむ"
        time: Math.floor(Date.now() / 1000) - 60
        bbs: location.href.split("/")[5]
        key: location.href.split("/")[6]

      arg = app.url.parse_query(location.href)
      form_data.FROM = arg.rcrx_name
      form_data.mail = arg.rcrx_mail
      form_data.MESSAGE = arg.rcrx_message

      for key, val of form_data
        input = document.createElement("input")
        input.name = key
        input.setAttribute("value", val)
        form.appendChild(input)

      console.log(form)
      form.__proto__.submit.call(form)

    else if ///^http://\w+\.2ch\.net/test/bbs\.cgi///.test(location.href)
      if /書きこみました/.test(document.title)
        exec """
          parent.postMessage(JSON.stringify({type : "success"}), "#{origin}");
        """

      else if /確認/.test(document.title)
        exec """
          parent.postMessage(JSON.stringify({type : "confirm"}), "#{origin}");
        """

      else if /ＥＲＲＯＲ/.test(document.title)
        exec """
          parent.postMessage(JSON.stringify({type : "error"}), "#{origin}");
        """

  boot = ->
    window.addEventListener "message", (e) ->
      if e.origin is origin and e.data is "write_iframe_pong"
        main()

    exec """
      parent.postMessage(JSON.stringify({type : "ping"}), "#{origin}");
    """

  setTimeout(boot, 0)
)()
