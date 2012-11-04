describe "UI.Accordion", ->
  $accordion = null
  accordion = null

  beforeEach ->
    html = """
      <div>
        <h2>test0</h2>
        <div>content0</div>
        <h2>test1</h2>
        <div>content1</div>
        <h2>test2</h2>
        <div>content2</div>
      </div>
    """

    $accordion = $(html).appendTo("#qunit-fixture")
    accordion = new UI.Accordion($accordion[0])
    return

  it "アコーディオンに.accordionを付与する", ->
    expect($accordion.is(".accordion")).toBeTruthy()
    return

  it "項目をクリックするとその項目を開閉する", ->
    $header = $accordion.find("h2:first-child")
    $header.trigger("click")
    expect($header.hasClass("accordion_open")).toBeTruthy()
    $header.trigger("click")
    expect($header.hasClass("accordion_open")).toBeFalsy()
    return

  describe "::open", ->
    it "項目を開く時、他の開いている項目を閉じる", ->
      $a = $accordion.find("h2:nth-child(1)")
      $b = $accordion.find("h2:nth-child(3)")

      accordion.open($b[0])
      expect($a.hasClass("accordion_open")).toBeFalsy()
      expect($b.hasClass("accordion_open")).toBeTruthy()

      accordion.open($a[0])
      expect($a.hasClass("accordion_open")).toBeTruthy()
      expect($b.hasClass("accordion_open")).toBeFalsy()
      return
    return
  return
