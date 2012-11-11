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

describe "UI.SelectableAccordion", ->
  div = null
  accordion = null

  beforeEach ->
    div = document.createElement("div")
    div.innerHTML = """
    <h3 class="header0">header0</h3>
    <ul class="ul0">
      <li><a class="a0">a0</a></li>
      <li><a class="a1">a1</a></li>
      <li><a class="a2">a2</a></li>
    </ul>
    <h3 class="header1">header1</h3>
    <ul class="ul1">
      <li><a class="a3">a3</a></li>
    </ul>
    <h3 class="header2">header2</h3>
    <ul class="ul2">
      <li><a class="a4">a4</a></li>
      <li><a class="a5">a5</a></li>
      <li><a class="a6">a6</a></li>
    </ul>
    """

    document.getElementById("qunit-fixture").appendChild(div)
    accordion = new UI.SelectableAccordion(div)
    return

  describe "::select", ->
    it "ターゲットの要素に.selectableを付与する", ->
      target = div.querySelector(".a0")
      accordion.select(target)
      expect(target.classList.contains("selected")).toBeTruthy()
      return

    it "ターゲットの要素以外から.selectableを除去する", ->
      a = div.querySelector(".a5")
      b = div.querySelector(".header1")

      accordion.select(a)
      accordion.select(b)
      expect(a.classList.contains("selected")).toBeFalsy()
      expect(b.classList.contains("selected")).toBeTruthy()
      return

    it "h3.accordion_openが選択された場合はそのh3をcloseする", ->
      spyOn(UI.SelectableAccordion::, "close")

      header = div.querySelector(".header0")
      accordion.open(header)
      accordion.select(header)

      expect(UI.SelectableAccordion::close).toHaveBeenCalledWith(header)
      return

    it "openされていない箇所のaが選択された場合、該当するh3をopenする", ->
      spyOn(UI.SelectableAccordion::, "open")

      header = div.querySelector(".header0")
      a = div.querySelector(".a0")
      accordion.select(a)

      expect(UI.SelectableAccordion::open).toHaveBeenCalledWith(header)
      return
    return

  describe "::selectNext", ->
    describe "何も選択されていない時", ->
      it ".accordion_open + ul aが有ればそれを選択する", ->
        accordion.open(div.querySelector(".header0"))
        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select)
          .toHaveBeenCalledWith(div.querySelector(".a0"))
        return

      it "無ければh3を選択する", ->
        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select)
          .toHaveBeenCalledWith(div.querySelector(".header0"))
        return
      return

    describe "Aが選択されている時", ->
      it "次のli > aが有れば、それを選択する", ->
        a0 = div.querySelector(".a0")
        a1 = div.querySelector(".a1")

        accordion.select(a0)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(a1)
        return

      it "ul内最後のli > aだった場合、次のh3を選択する", ->
        a = div.querySelector(".a2")
        header = div.querySelector(".header1")

        accordion.select(a)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(header)
        return

      it "次に選択する要素が無かった場合、何もしない", ->
        accordion.select(div.querySelector(".a6"))

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select).not.toHaveBeenCalled()
        return
      return

    describe "H3が選択されている時", ->
      it "次のh3が有れば、それを選択する", ->
        header0 = div.querySelector(".header0")
        header1 = div.querySelector(".header1")

        accordion.select(header0)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(header1)
        return

      it "次のh3が.accordion_openだった場合、その最初のli > aを選択する", ->
        header0 = div.querySelector(".header0")
        header1 = div.querySelector(".header1")
        a = div.querySelector(".a3")

        accordion.select(header0)
        accordion.open(header1)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(a)
        return

      it "次に選択する要素が無かった場合、何もしない", ->
        accordion.select(div.querySelector(".header2"))

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select).not.toHaveBeenCalled()
        return
      return
    return

  describe "::selectPrev", ->
    describe "何も選択されていない時", ->
       it ".accordion_open + ul aが有ればそれを選択する", ->
        accordion.open(div.querySelector(".header0"))
        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select)
          .toHaveBeenCalledWith(div.querySelector(".a0"))
        return

      it "無ければh3を選択する", ->
        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectNext()

        expect(UI.SelectableAccordion::select)
          .toHaveBeenCalledWith(div.querySelector(".header0"))
        return
      return

    describe "Aが選択されている時", ->
      it "前のli > aが有れば、それを選択する", ->
        a0 = div.querySelector(".a0")
        a1 = div.querySelector(".a1")

        accordion.select(a1)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectPrev()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(a0)
        return

      it "ul内最初のli > aだった場合、前のh3を選択する", ->
        a = div.querySelector(".a3")
        header = div.querySelector(".header0")

        accordion.select(a)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectPrev()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(header)
        return

      it "次に選択する要素が無かった場合、何もしない", ->
        accordion.select(div.querySelector(".a0"))

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectPrev()

        expect(UI.SelectableAccordion::select).not.toHaveBeenCalled()
        return
      return

    describe "H3が選択されている時", ->
      it "前のh3が有れば、それを選択する", ->
        header0 = div.querySelector(".header0")
        header1 = div.querySelector(".header1")

        accordion.select(header1)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectPrev()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(header0)
        return

      it "前のh3が.accordion_openだった場合、その最後のli > aを選択する", ->
        header0 = div.querySelector(".header0")
        header1 = div.querySelector(".header1")
        a = div.querySelector(".a2")

        accordion.select(header1)
        accordion.open(header0)

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectPrev()

        expect(UI.SelectableAccordion::select).toHaveBeenCalledWith(a)
        return

      it "次に選択する要素が無かった場合、何もしない", ->
        accordion.select(div.querySelector(".header0"))

        spyOn(UI.SelectableAccordion::, "select")

        accordion.selectPrev()

        expect(UI.SelectableAccordion::select).not.toHaveBeenCalled()
        return
      return
    return
  return
