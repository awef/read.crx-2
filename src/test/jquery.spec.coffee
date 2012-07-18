describe "Modified jQuery", ->
  it "バブリングしてきたミドルクリックのイベントも検出する", ->
    onClick = jasmine.createSpy("onClick")

    $("<div><p></p></div>")
      .appendTo("body")
      .on("click", "p", onClick)
      .find("p")
        .trigger(type: "click", button: 1, which: 2)
      .end()
      .remove()

    expect(onClick.callCount).toBe(1)
    e = onClick.mostRecentCall.args[0]
    expect(e.button).toBe(1)
    expect(e.which).toBe(2)
  return
