regs = [
  ///^http://(?!find|info|p2)\w+\.2ch\.net/\w+/(?:#\d+)?$///
  ///^http://\w+\.2ch\.net/test/read\.cgi/\w+/\d+///
  ///^http://jbbs\.livedoor\.jp/\w+/\d+/(?:#\d+)?$///
  ///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/\w+/\d+/\d+///
  ///^http://\w+\.machi\.to/\w+/(?:#\d+)?$///
  ///^http://\w+\.machi\.to/bbs/read\.cgi/\w+/\d+///
]

if (regs.some (a) -> a.test(location.href))
  container = document.createElement("div")
  style =
    position: "fixed"
    right: "10px"
    top: "40px"
    "background-color": "rgba(255,255,255,0.8)"
    color: "#000"
    border: "1px solid black"
    "border-radius": "4px"
    padding: "5px"
    "font-size": "14px"
    "font-weight": "normal"

  for key, val of style
    container.style[key] = val

  open_button = document.createElement("span")
  open_button.textContent = "read.crx 2 で開く"
  open_button.style["cursor"] = "pointer"
  open_button.style["text-decoration"] = "underline"
  open_button.addEventListener "click", ->
    url = chrome.extension.getURL("app.html")
    url += "?q=#{encodeURIComponent(location.href)}"
    open(url)
  container.appendChild(open_button)

  close_button = document.createElement("span")
  close_button.textContent = " x"
  close_button.style["cursor"] = "pointer"
  close_button.style["display"] = "inline-block"
  close_button.style["margin-left"] = "5px"
  close_button.addEventListener "click", ->
    this.parentNode.parentNode.removeChild(this.parentNode)
  container.appendChild(close_button)

  document.body.appendChild(container)
