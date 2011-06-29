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

asyncTest "pc11/linux → hibari/linux", 1, ->
  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/")
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hibari.2ch.net/linux/")
      start()

asyncTest "yuzuru/gameswf → hato/gameswf", 1, ->
  app.util.ch_server_move_detect("http://yuzuru.2ch.net/gameswf/")
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hato.2ch.net/gameswf/")
      start()

asyncTest "example.com", 1, ->
  app.util.ch_server_move_detect("http://example.com/")
    .fail ->
      ok(true)
      start()

