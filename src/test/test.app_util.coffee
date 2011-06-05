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
