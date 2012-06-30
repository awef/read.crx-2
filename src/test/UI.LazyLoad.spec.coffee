describe "UI.LazyLoad", ->
  div = null
  lazyLoad = null

  getDummyURL = do ->
    count = 0
    -> location.origin + "/img/dummy_1x1.png?#{++count}"

  getDummyIMG = ->
    img = document.createElement("img")
    img.src = getDummyURL()
    img.setAttribute("data-src", getDummyURL())
    img

  beforeEach ->
    UI.LazyLoad.__UPDATE_INTERVAL = UI.LazyLoad.UPDATE_INTERVAL
    UI.LazyLoad.UPDATE_INTERVAL = 50

    div = document.createElement("div")
    div.style.width = "100px"
    div.style.height = "100px"
    document.body.appendChild(div)
    lazyLoad = new UI.LazyLoad(div)
    return

  afterEach ->
    lazyLoad._unwatch()
    div.parentNode?.removeChild(div)

    UI.LazyLoad.UPDATE_INTERVAL = UI.LazyLoad.__UPDATE_INTERVAL
    delete UI.LazyLoad.__UPDATE_INTERVAL
    return

  it "new時に::scanを呼ぶ", ->
    spyOn(UI.LazyLoad::, "scan").andCallThrough()

    lazyLoad = new UI.LazyLoad(document.createElement("div"))

    expect(UI.LazyLoad::scan.calls.length).toBe(1)
    return

  describe "::update", ->
    it "遅延ロード対象が無い場合は::_unwatchを呼ぶ", ->
      spyOn(lazyLoad, "_unwatch").andCallThrough()

      lazyLoad.update()

      expect(lazyLoad._unwatch).toHaveBeenCalled()
      return

    it "遅延ロード対象のロード判定を行う", ->
      div.style.position = "relative"
      div.appendChild(img1 = getDummyIMG())
      img1.style.position = "absolute"
      img1.style.top = "200px"
      div.appendChild(img2 = getDummyIMG())
      img2.style.position = "absolute"
      img2.style.top = "10px"
      div.appendChild(img3 = getDummyIMG())
      img3.style.position = "absolute"
      img3.style.top = "200px"
      spyOn(lazyLoad, "update").andCallThrough()
      spyOn(lazyLoad, "_load").andCallThrough()

      lazyLoad.scan()

      expect(lazyLoad.update.calls.length).toBe(1)

      waitsFor -> lazyLoad._load.wasCalled

      runs ->
        expect(lazyLoad._load).toHaveBeenCalledWith(img2)
        return
      return

    it "::_loadに渡したimgは_imgsから削除する", ->
      div.style.position = "relative"
      div.appendChild(img1 = getDummyIMG())
      img1.style.position = "absolute"
      img1.style.top = "10px"
      div.appendChild(img2 = getDummyIMG())
      img2.style.position = "absolute"
      img2.style.top = "200px"
      div.appendChild(img3 = getDummyIMG())
      img3.style.position = "absolute"
      img3.style.top = "200px"
      spyOn(lazyLoad, "update").andCallThrough()
      spyOn(lazyLoad, "_load").andCallThrough()

      lazyLoad.scan()

      waitsFor -> lazyLoad._load.wasCalled

      runs ->
        expect(lazyLoad._imgs).toEqual([img2, img3])
        return
      return
    return

  describe "::_watch", ->
    it "スクロール検出時に::updateを呼ぶようにする", ->
      spyOn(lazyLoad, "update").andCallThrough()

      lazyLoad._watch()
      lazyLoad._onScroll()

      expect(lazyLoad._updateInterval).toEqual(jasmine.any(Number))

      waitsFor -> lazyLoad.update.wasCalled

      runs ->
        expect(lazyLoad.update).toHaveBeenCalled()
        return
      return

    it "::updateを呼んだ後、スクロールフラグをクリアする", ->
      spyOn(lazyLoad, "update").andCallThrough()

      lazyLoad._watch()
      lazyLoad._onScroll()

      waitsFor -> lazyLoad.update.wasCalled

      runs ->
        expect(lazyLoad._scroll).toBe(false)
        return
      return
    return

  describe "::_unwatch", ->
    it "スクロールの監視を解除する", ->
      spyOn(lazyLoad, "update").andCallThrough()

      lazyLoad._watch()
      lazyLoad._unwatch()
      lazyLoad._onScroll()

      expect(lazyLoad._updateInterval).toBe(null)

      timeout = false
      setTimeout((-> timeout = true; return), UI.LazyLoad.UPDATE_INTERVAL * 1.2)
      waitsFor -> timeout

      runs ->
        expect(lazyLoad.update).not.toHaveBeenCalled()
        return
      return
    return

  describe "::scan", ->
    it "遅延ロード対象のimgを@_imgsに格納する", ->
      div.appendChild(img1 = getDummyIMG())
      div.appendChild(img2 = getDummyIMG())
      div.appendChild(img3 = getDummyIMG())

      lazyLoad.scan()

      expect(lazyLoad._imgs).toEqual([img1, img2, img3])
      return

    it "遅延ロード対象を見つけた場合は即座に::updateを呼び、監視を開始する", ->
      spyOn(lazyLoad, "update").andCallThrough()
      spyOn(lazyLoad, "_watch").andCallThrough()

      img = getDummyIMG()
      div.appendChild(img)
      lazyLoad.scan()

      expect(lazyLoad.update.calls.length).toBe(1)
      expect(lazyLoad._watch.calls.length).toBe(1)
      return

    it "遅延ロード対象が無い場合は監視を停止する", ->
      spyOn(lazyLoad, "_unwatch").andCallThrough()

      lazyLoad.scan()

      expect(lazyLoad._unwatch.calls.length).toBe(1)
      return
    return

  describe "::_load", ->
    it "遅延ロード対象のimgのロードを開始する", ->
      div.appendChild(img = getDummyIMG())
      src = img.getAttribute("data-src")

      lazyLoad._load(img)

      waitsFor -> img.parentNode isnt div

      runs ->
        expect(div.querySelector("img").src).toBe(src)
        expect(div.querySelector("img").getAttribute("data-src")).toBe(null)
        return
      return

    it "ロード成功時にimg要素にlazyload-loadイベントを送出する", ->
      div.appendChild(img = getDummyIMG())
      onLazyloadLoad= jasmine.createSpy("onLazyloadLoad")
      $(div).on("lazyload-load", onLazyloadLoad)

      lazyLoad._load(img)

      waitsFor -> onLazyloadLoad.wasCalled

      runs ->
        expect(onLazyloadLoad.calls.length).toBe(1)
        return
      return

    it "元画像の属性を移植する（data-src属性以外）", ->
      div.appendChild(img1 = getDummyIMG())
      img1.id = "f62106a4"
      img1.className = "icon"
      img1.setAttribute("data-test", "12345")

      lazyLoad._load(img1)

      waitsFor -> img1.parentNode isnt div

      runs ->
        img2 = div.querySelector("img")
        expect(img2.id).toBe(img1.id)
        expect(img2.className).toBe(img1.className)
        expect(img2.getAttribute("data-test")).toBe("12345")
        expect(img2.getAttribute("data-src")).toBe(null)
        return
      return
    return
  return
