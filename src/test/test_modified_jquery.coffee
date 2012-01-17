module("Modified jQuery")

test "バブリングしてきたミドルクリックのイベントも検出出来る", 2, ->
  $("<div><p></p></div>")
    .appendTo("#qunit-fixture")
    .on "click", "p", (e) ->
      strictEqual(e.button, 1)
      strictEqual(e.which, 2)
      return
    .find("p")
      .trigger(type: "click", button: 1, which: 2)
  return
