describe "UI.Tab", ->
  getDummyURL = do ->
    count = 0
    -> location.origin + "/view/empty.html?#{++count}"

  emptyURL = location.origin + "/view/empty.html"

  div = null
  tab = null

  beforeEach ->
    div = document.createElement("div")
    tab = new UI.Tab(div)
    return

  it "new時に必要な要素を生成する", ->
    tmp = """
    <div class="tab">
      <div class="tab_tabbar"></div>
      <div class="tab_container"></div>
    </div>
    """.replace(/\u0020{2}|\n/g, "")

    expect(div.outerHTML).toEqual(tmp)
    return

  describe "::add", ->
    it "既存のタブが無い時、追加されたタブを必ず選択する", ->
      url = getDummyURL()

      tab.add(url, selected: false, lazy: true)

      expect(tab.getSelected().url).toBe(url)
      return

    it "デフォルトで追加タブを選択状態にする", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      tab.add(url1)
      tab.add(url2)

      expect(tab.getSelected().url).toBe(url2)
      return

    it "タイトルが指定された場合は、それを用いる", ->
      url = getDummyURL()

      tab.add(url, title: "test")

      expect(tab.getSelected().title).toBe("test")
      return

    it "タイトルが指定されなかった場合、URLをタイトルとして用いる", ->
      url = getDummyURL()

      tab.add(url)

      expect(tab.getSelected().title).toBe(url)
      return

    it "遅延読み込み指定で開かれたタブは、選択されるまでロードしない", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      tab.add(url1)
      tab.add(url2, selected: false, lazy: true)

      expect(div.querySelector("iframe:nth-child(2)").src).toBe(emptyURL)

      url2tabId = tab.getAll().filter((a) -> a.url is url2)[0].tabId
      tab.update(url2tabId, selected: true)

      waitsFor ->
        div.querySelector("iframe:nth-child(2)").src is url2

      runs ->
        expect(div.querySelector("iframe:nth-child(2)").src).toBe(url2)
        return
      return

    it "複数のタブが一度に遅延ロード指定で開かれた時、最終的にタブが選択されるかどうかのみを考慮する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()
      url3 = getDummyURL()

      tab.add(url1, lazy: true)
      tab.add(url2, lazy: true)
      tab.add(url3, lazy: true)

      waitsFor ->
        div.querySelector("iframe:nth-child(3)").src is url3

      runs ->
        expect(div.querySelector("iframe:nth-child(1)").src).toBe(emptyURL)
        expect(div.querySelector("iframe:nth-child(2)").src).toBe(emptyURL)
        expect(div.querySelector("iframe:nth-child(3)").src).toBe(url3)
        return
      return
    return

  describe "::remove", ->
    it "タブ削除時、iframeにtab_removedイベントを送出する", ->
      url = getDummyURL()

      onTabRemoved = jasmine.createSpy("onTabRemoved")
      $(div).one("tab_removed", "iframe", onTabRemoved)

      tab.add(url)
      tab.remove(tab.getSelected().tabId)

      expect(onTabRemoved.calls.length).toBe(1)
      return

    it "アクティブなタブの削除時、右側のタブを選択する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()
      url3 = getDummyURL()

      tab.add(url1)
      tab.add(url2)
      tab.add(url3)
      tab2id = tab.getAll().filter((a) -> a.url is url2)[0].tabId
      tab.update(tab2id, selected: true)
      tab.remove(tab2id)

      expect(tab.getSelected().url).toBe(url3)
      return

    it "アクティブなタブの削除時、右側のタブが無ければ左側のタブを選択する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()
      url3 = getDummyURL()

      tab.add(url1)
      tab.add(url2)
      tab.add(url3)
      tab.remove(tab.getSelected().tabId)

      expect(tab.getSelected().url).toBe(url2)
      return
    return

  describe "::update", ->
    it "タイトルを変更する", ->
      url = getDummyURL()

      tab.add(url)
      expect(tab.getSelected().title).toBe(url)
      tab.update(tab.getSelected().tabId, title: "test")
      expect(tab.getSelected().title).toBe("test")
      return

    it "タブのURLを変更する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      tabId = tab.add(url1)
      expect(tab.getSelected().url).toBe(url1)
      tab.update(tabId, url: url2)
      expect(tab.getSelected().url).toBe(url2)
      return

    it "タブのURL変更時、iframeにtab_urlupdatedイベントを送出する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      onTabURLUpdated = jasmine.createSpy("onTabSelected")
      $(div).one("tab_selected", "iframe", onTabURLUpdated)

      tabId = tab.add(url1)
      tab.update(tabId, url: url2)

      expect(onTabURLUpdated.calls.length).toBe(1)
      return

    it "タブ選択時、iframeにtab_selectedイベントを送出する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      tab.add(url1)
      tab.add(url2)

      onTabSelected = jasmine.createSpy("onTabSelected")
      $(div).one("tab_selected", "iframe", onTabSelected)

      tab1id = tab.getAll().filter((a) -> a.url is url1)[0].tabId
      tab.update(tab1id, selected: true)

      expect(onTabSelected.calls.length).toBe(1)
      return
    return
  return
