app.url = {}
app.url.fix = (url) ->
  url
    .replace(///
      ^(http://
        (?:
          [\w\.]+/test/read\.cgi/\w+/\d+
        | \w+\.machi\.to/bbs/read\.cgi/\w+/\d+
        | jbbs\.livedoor\.jp/bbs/read\.cgi/\w+/\d+/\d+
        | [\w\.]+/\w+(?:/\d+)?
        )
      ).*?$
      ///, "$1/")

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
  else if ///^http://[\w\.]+/\w+/$///.test(url)
    {type: "board", bbs_type: "2ch"}
  else
    return {type: "unknown", bbs_type: "unknown"};

app.url.thread_to_board = (thread_url) ->
  app.url.fix(thread_url)
    .replace(///^http://([\w\.]+)/(?:test|bbs)/read\.cgi/(\w+)/\d+/$///, "http://$1/$2/")
    .replace(///^http://jbbs\.livedoor\.jp/bbs/read\.cgi/(\w+)/(\d+)/\d+/$///, "http://jbbs.livedoor.jp/$1/$2/")

app.url._parse_query = (str) ->
  data = {}
  for segment in str.split("&")
    tmp = segment.split("=")
    data[decodeURIComponent(tmp[0])] = (
      if 1 of tmp then decodeURIComponent(tmp[1]) else true
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
