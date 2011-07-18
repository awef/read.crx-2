app.url = {}
app.url.fix = (url) ->
  url
    #スレ系 誤爆する事は考えられないので、パラメータ部分をバッサリ切ってしまう
    .replace(/// ^(http://[\w\.]+/test/read\.cgi/\w+/\d+).*?$ ///, "$1/")
    .replace(/// ^(http://\w+\.machi\.to/bbs/read\.cgi/\w+/\d+).*?$ ///, "$1/")
    .replace(/// ^(http://jbbs\.livedoor\.jp/bbs/read\.cgi/\w+/\d+/\d+).*?$ ///, "$1/")
    #板系 完全に誤爆を少しでも減らすために、パラメータ形式も限定する
    .replace(/// ^(http://[\w\.]+/\w+/)(?:#.*)?$ ///, "$1")
    .replace(/// ^(http://jbbs\.livedoor\.jp/\w+/\d+/)(?:#.*)?$ ///, "$1")

app.url.guess_type = (url) ->
  url = app.url.fix(url)
  if ///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/\w+/\d+/\d+/$///.test(url)
    {type: "thread", bbs_type: "jbbs"}
  else if ///^http://jbbs\.livedoor\.jp/\w+/\d+/$///.test(url)
    {type: "board", bbs_type: "jbbs"}
  else if ///^http://\w+\.machi\.to/bbs/read\.cgi/\w+/\d+/$///.test(url)
    {type: "thread", bbs_type: "machi"}
  else if ///^http://\w+\.machi\.to/\w+/$///.test(url)
    {type: "board", bbs_type: "machi"}
  else if ///^http://[\w\.]+/test/read\.cgi/\w+/\d+/$///.test(url)
    {type: "thread", bbs_type: "2ch"}
  else if ///^http://(?:find|info|p2|ninja)\.2ch\.net/\w+/$///.test(url)
    {type: "unknown", bbs_type: "unknown"}
  else if ///^http://[\w\.]+/\w+/$///.test(url)
    {type: "board", bbs_type: "2ch"}
  else
    {type: "unknown", bbs_type: "unknown"}

app.url.tsld = (url) ->
  /// ^https?://(?:\w+\.)*(\w+\.\w+)/ ///.exec(url)?[1] or ""

app.url.thread_to_board = (thread_url) ->
  app.url.fix(thread_url)
    .replace(///^http://([\w\.]+)/(?:test|bbs)/read\.cgi/(\w+)/\d+/$///, "http://$1/$2/")
    .replace(///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/(\w+)/(\d+)/\d+/$///, "http://jbbs.livedoor.jp/$1/$2/")

app.url._parse_query = (str) ->
  data = {}
  for segment in str.split("&")
    tmp = segment.split("=")
    data[decodeURIComponent(tmp[0])] = (
      if tmp[1]? then decodeURIComponent(tmp[1]) else true
    )
  data

app.url.parse_query = (url) ->
  tmp = /\?([^#]+)(:?\#.*)?$/.exec(url)
  if tmp then app.url._parse_query(tmp[1]) else {}

app.url.parse_hashquery = (url) ->
  tmp = /#(.+)$/.exec(url)
  if tmp then app.url._parse_query(tmp[1]) else {}

app.url.build_param = (data) ->
  str = ""
  for key, val of data
    if val is true
      str += "&#{encodeURIComponent(key)}"
    else
      str += "&#{encodeURIComponent(key)}=#{encodeURIComponent(val)}"
  str.slice(1)
