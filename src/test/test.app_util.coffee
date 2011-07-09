module "app.util.parse_anchor"

test "test", ->
  expected =
    data: [
      segments: [[1, 1]]
      target: 1
    ]
    target: 1

  deepEqual(app.util.parse_anchor(">>1"), expected)
  deepEqual(app.util.parse_anchor(">1"), expected)
  deepEqual(app.util.parse_anchor("&gt;&gt;1"), expected)
  deepEqual(app.util.parse_anchor("&gt;1"), expected)
  deepEqual(app.util.parse_anchor("＞＞1"), expected)
  deepEqual(app.util.parse_anchor("＞1"), expected)

  deepEqual app.util.parse_anchor(">>1"),
    {data: [{segments: [[1, 1]], target: 1}], target: 1}
  deepEqual app.util.parse_anchor(">>100"),
    {data: [{segments: [[100, 100]], target: 1}], target: 1}
  deepEqual app.util.parse_anchor(">>1000"),
    {data: [{segments: [[1000, 1000]], target: 1}], target: 1}
  deepEqual app.util.parse_anchor(">>10000"),
    {data: [{segments: [[10000, 10000]], target: 1}], target: 1}

  deepEqual app.util.parse_anchor(">>1,2,3"),
    {data: [{segments: [[1, 1], [2, 2], [3, 3]], target: 3}], target: 3}
  deepEqual app.util.parse_anchor(">>1, 2, 3"),
    {data: [{segments: [[1, 1], [2, 2], [3, 3]], target: 3}], target: 3}
  deepEqual app.util.parse_anchor(">>1,    2, 3"),
    {data: [{segments: [[1, 1], [2, 2], [3, 3]], target: 3}], target: 3}

  deepEqual app.util.parse_anchor(">>1-3"),
    {data: [{segments: [[1, 3]], target: 3}], target: 3}
  deepEqual app.util.parse_anchor(">>1ー3"),
    {data: [{segments: [[1, 3]], target: 3}], target: 3}
  deepEqual app.util.parse_anchor(">>1ー3, 4ー6"),
    {data: [{segments: [[1, 3], [4, 6]], target: 6}], target: 6}

module "app.util.ch_sever_move_detect"

asyncTest "dummy", 1, ->
  html = "dummy"
  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/", html)
    .fail ->
      ok(true)
      start()

asyncTest "pc11/linux → hibari/linux (html)", 1, ->
  html = """
  <html>
  <head>
  <script language="javascript">
  window.location.href="http://hibari.2ch.net/linux/"</script>
  <title>2chbbs..</title>
  <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=Shift_JIS">
  </head>
  <body bgcolor="#FFFFFF">
  Change your bookmark ASAP.
  <a href="http://hibari.2ch.net/linux/">GO !</a>
  </body>
  </html>
  """

  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/", html)
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hibari.2ch.net/linux/")
      start()

asyncTest "pc11/linux → hibari/linux (xhr)", 1, ->
  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/")
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hibari.2ch.net/linux/")
      start()

asyncTest "yuzuru/gameswf → hato/gameswf (xhr)", 1, ->
  app.util.ch_server_move_detect("http://yuzuru.2ch.net/gameswf/")
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hato.2ch.net/gameswf/")
      start()

asyncTest "example.com (xhr)", 1, ->
  app.util.ch_server_move_detect("http://example.com/")
    .fail ->
      ok(true)
      start()

module "app.util.decode_char_reference"

test "test", ->
  fn = (a, b) ->
    strictEqual(app.util.decode_char_reference(a), b)

    x = app.util.decode_char_reference(a)
    if x isnt b
      console.log x.length, b.length
      console.log x.charCodeAt(0), b.charCodeAt(0)

  #数値文字参照テスト(10進数)
  fn("&#0161;", "¡")
  fn("&#0165;", "¥")
  fn("&#0169;", "©")
  fn("&#0181;", "µ")
  fn("&#0255;", "ÿ")

  #数値文字参照テスト(16進数)
  fn("&#x00A1;", "¡")
  fn("&#x00A5;", "¥")
  fn("&#x00A9;", "©")
  fn("&#x00B5;", "µ")
  fn("&#x00FF;", "ÿ")

  #数値文字参照テスト(16進数 小文字)
  fn("&#x00a1;", "¡")
  fn("&#x00a5;", "¥")
  fn("&#x00a9;", "©")
  fn("&#x00b5;", "µ")
  fn("&#x00ff;", "ÿ")

  #XML実体参照テスト
  fn("&amp;", "&")
  fn("&lt;", "<")
  fn("&gt;", ">")
  fn("&quot;", "\"")
  fn("&apos;", "'")

  #実例テスト
  fn("★☆★【雲雀|朱鷺】VIP&amp;VIP+運用情報387★☆★",
    "★☆★【雲雀|朱鷺】VIP&VIP+運用情報387★☆★")

  fn("お、おい！&gt;&gt;5が息してねえぞ！",
    "お、おい！>>5が息してねえぞ！")

  fn("【ブログ貼付】 &lt;iframe&gt;タグの不具合 ",
    "【ブログ貼付】 <iframe>タグの不具合 ")

