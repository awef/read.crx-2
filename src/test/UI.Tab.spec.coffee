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
      <ul class="tab_tabbar"></ul>
      <div class="tab_container"></div>
    </div>
    """.replace(/\u0020{2}|\n/g, "")

    expect(div.outerHTML).toEqual(tmp)
    return

  describe "@historyStore", ->
    it "タブ毎の履歴が格納される", ->
      tmp = {}

      # タブ追加
      url1 = getDummyURL()
      tabId1 = tab.add(url1)
      tmp[tabId1] = {
        current: 0
        stack: [
          {url: url1, title: url1}
        ]
      }
      expect(tab.historyStore).toEqual(tmp)

      # タブ追加（タイトル指定）
      url2 = getDummyURL()
      tabId2 = tab.add(url2, title: "test")
      tmp[tabId2] = {
        current: 0
        stack: [
          {url: url2, title: "test"}
        ]
      }
      expect(tab.historyStore).toEqual(tmp)

      # タイトル変更
      tab.update(tabId1, title: "test2")
      tmp[tabId1].stack[0].title = "test2"
      expect(tab.historyStore).toEqual(tmp)

      # URL変更
      url3 = getDummyURL()
      tab.update(tabId1, url: url3)
      tmp[tabId1].current++
      tmp[tabId1].stack.push(url: url3, title: url3)
      expect(tab.historyStore).toEqual(tmp)

      # URL変更（タイトル指定）
      url4 = getDummyURL()
      tab.update(tabId1, url: url4, title: "test3")
      tmp[tabId1].current++
      tmp[tabId1].stack.push(url: url4, title: "test3")
      expect(tab.historyStore).toEqual(tmp)

      # URL変更
      url5 = getDummyURL()
      tab.update(tabId1, url: url5, title: "test4")
      tmp[tabId1].current++
      tmp[tabId1].stack.push(url: url5, title: "test4")
      expect(tab.historyStore).toEqual(tmp)

      # requestTabBack時と同等の処理
      tab.historyStore[tabId1].current--
      tmp[tabId1].current--
      tab.update(tabId1, {
        title: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].title
        url: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].url
        _internal: true
      })
      expect(tab.historyStore).toEqual(tmp)

      # requestTabForward時と同等の処理
      tab.historyStore[tabId1].current++
      tmp[tabId1].current++
      tab.update(tabId1, {
        title: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].title
        url: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].url
        _internal: true
      })
      expect(tab.historyStore).toEqual(tmp)

      # requestTabBack時と同等の処理
      tab.historyStore[tabId1].current--
      tmp[tabId1].current--
      tab.update(tabId1, {
        title: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].title
        url: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].url
        _internal: true
      })
      expect(tab.historyStore).toEqual(tmp)

      # requestTabBack時と同等の処理
      tab.historyStore[tabId1].current--
      tmp[tabId1].current--
      tab.update(tabId1, {
        title: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].title
        url: tab.historyStore[tabId1].stack[tab.historyStore[tabId1].current].url
        _internal: true
      })
      expect(tab.historyStore).toEqual(tmp)

      # requestTabBack処理後に移動した場合
      url6 = getDummyURL()
      tab.update(tabId1, url: url6)
      tmp[tabId1].stack.splice(tmp[tabId1].current + 1)
      tmp[tabId1].current++
      tmp[tabId1].stack.push(url: url6, title: url6)
      expect(tab.historyStore).toEqual(tmp)
      return

    it "閉じたタブの履歴は五十個まで保持する", ->
      for [0...55]
        tab.remove(tab.add(getDummyURL()))

      expect(Object.keys(tab.historyStore).length).toBe(50)
      return

    return

  describe "::add", ->
    it "タブを追加する", ->
      id = tab.add(url = getDummyURL())

      expect(div.querySelectorAll("[data-tabid=\"#{id}\"]").length).toBe(2)
      expect(div.querySelectorAll("li[data-tabid=\"#{id}\"]").length).toBe(1)
      expect(div.querySelectorAll("iframe[data-tabid=\"#{id}\"]").length).toBe(1)
      expect(tab.getAll()).toEqual([{tabId: id, url, title: url, selected: true}])
      return

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
    it "タブを削除する", ->
      tab.remove(tab.add(getDummyURL()))

      expect(div.querySelectorAll("li, iframe").length).toBe(0)
      expect(tab.getAll().length).toBe(0)
      return

    it "タブ削除時、iframeにtab_removedイベントを送出する", ->
      url = getDummyURL()

      onTabRemoved = jasmine.createSpy("onTabRemoved")
      $(div).one("tab_removed", "iframe", onTabRemoved)

      tab.add(url)
      tab.remove(tab.getSelected().tabId)

      expect(onTabRemoved.callCount).toBe(1)
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
    it "タブの選択状態を変更する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()
      url3 = getDummyURL()

      id1 = tab.add(url1)
      id2 = tab.add(url2)
      id3 = tab.add(url3)

      li1 = div.querySelector("li[data-tabid=\"#{id1}\"]")
      li2 = div.querySelector("li[data-tabid=\"#{id2}\"]")
      li3 = div.querySelector("li[data-tabid=\"#{id3}\"]")
      iframe1 = div.querySelector("iframe[data-tabid=\"#{id1}\"]")
      iframe2 = div.querySelector("iframe[data-tabid=\"#{id2}\"]")
      iframe3 = div.querySelector("iframe[data-tabid=\"#{id3}\"]")

      tab.update(id2, selected: true)
      expect(tab.getSelected().tabId).toBe(id2)
      expect(div.querySelector("li.tab_selected")).toBe(li2)
      expect(div.querySelector("iframe.tab_selected")).toBe(iframe2)

      tab.update(id1, selected: true)
      expect(tab.getSelected().tabId).toBe(id1)
      expect(div.querySelector("li.tab_selected")).toBe(li1)
      expect(div.querySelector("iframe.tab_selected")).toBe(iframe1)

      tab.update(id3, selected: true)
      expect(tab.getSelected().tabId).toBe(id3)
      expect(div.querySelector("li.tab_selected")).toBe(li3)
      expect(div.querySelector("iframe.tab_selected")).toBe(iframe3)
      return

    it "タイトルを変更する", ->
      url = getDummyURL()
      title = "test234"

      tab.add(url)
      li = div.querySelector("li")

      expect(tab.getSelected().title).toBe(url)
      expect(li.title).toBe(url)
      expect(li.firstChild.textContent).toBe(url)

      tab.update(tab.getSelected().tabId, {title})

      expect(tab.getSelected().title).toBe(title)
      expect(li.title).toBe(title)
      expect(li.firstChild.textContent).toBe(title)
      return

    it "タブのURLを変更する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      tabId = tab.add(url1)
      li = div.querySelector("li.tab_selected")
      iframe = div.querySelector("iframe.tab_selected")

      expect(tab.getSelected().url).toBe(url1)
      expect(li.getAttribute("data-tabsrc")).toBe(url1)
      expect(iframe.src).toBe(url1)

      tab.update(tabId, url: url2)

      expect(tab.getSelected().url).toBe(url2)
      expect(li.getAttribute("data-tabsrc")).toBe(url2)
      expect(iframe.src).toBe(url2)
      return

    it "タブのURL変更前、iframeにtab_beforeurlupdateイベントを送出する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      onTabBeforeURLUpdate = jasmine.createSpy("onTabBeforeURLUpdate")
      onTabBeforeURLUpdate.andCallFake ->
        expect(@src).toBe(url1)
        return
      $(div).one("tab_beforeurlupdate", "iframe", onTabBeforeURLUpdate)

      tabId = tab.add(url1)
      tab.update(tabId, url: url2)

      expect(onTabBeforeURLUpdate.callCount).toBe(1)
      return

    it "タブのURL変更後、iframeにtab_urlupdatedイベントを送出する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      onTabURLUpdated = jasmine.createSpy("onTabURLUpdated")
      onTabURLUpdated.andCallFake ->
        expect(@src).toBe(url2)
        return
      $(div).one("tab_urlupdated", "iframe", onTabURLUpdated)

      tabId = tab.add(url1)
      tab.update(tabId, url: url2)

      expect(onTabURLUpdated.callCount).toBe(1)
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

      expect(onTabSelected.callCount).toBe(1)
      return
    return

  describe "::getRecentClosed", ->
    it "最近閉じたタブの一覧を返す", ->
      url1 = getDummyURL()
      url2 = getDummyURL()
      url3 = getDummyURL()

      id1 = tab.add(url1)
      id2 = tab.add(url2)
      id3 = tab.add(url3)

      tab.remove(id1)
      tab.remove(id3)
      tab.remove(id2)

      expect(tab.getRecentClosed()).toEqual([
        {tabId: id1, url: url1, title: url1}
        {tabId: id3, url: url3, title: url3}
        {tabId: id2, url: url2, title: url2}
      ])
      return

    it "タブの一覧は五十個まで保持する", ->
      for [0...55]
        tab.remove(tab.add(getDummyURL()))

      expect(tab.getRecentClosed().length).toBe(50)
      return

    it "同一のURLのタブの履歴は最新の物のみ残す", ->
      url1 = getDummyURL()
      url2 = getDummyURL()

      id1 = tab.add(url1)
      id2 = tab.add(url1)
      id3 = tab.add(url2)

      tab.remove(id1)
      tab.remove(id2)
      tab.remove(id3)

      expect(tab.getRecentClosed()).toEqual([
        {tabId: id2, url: url1, title: url1}
        {tabId: id3, url: url2, title: url2}
      ])
      return

    it "ディープコピーしたデータを返す", ->
      tab.remove(id1 = tab.add(url1 = getDummyURL()))
      tab.remove(id2 = tab.add(url2 = getDummyURL()))
      tab.remove(id3 = tab.add(url3 = getDummyURL()))

      tab.getRecentClosed().reverse()

      expect(tab.getRecentClosed()).toEqual([
        {tabId: id1, url: url1, title: url1}
        {tabId: id2, url: url2, title: url2}
        {tabId: id3, url: url3, title: url3}
      ])
      return
    return

  describe "::restoreClosed", ->
    it "指定されたタブを復元し、最近閉じたタブリストから削除する", ->
      url1 = getDummyURL()
      url2 = getDummyURL()
      url3 = getDummyURL()

      id1 = tab.add(url1)
      id2 = tab.add(url2)
      id3 = tab.add(url3)

      tab.remove(id1)
      tab.remove(id3)
      tab.remove(id2)

      id = tab.restoreClosed(id3)

      expect(tab.getRecentClosed()).toEqual([
        {tabId: id1, url: url1, title: url1}
        {tabId: id2, url: url2, title: url2}
      ])

      expect(tab.getAll()).toEqual([
        {tabId: id, url: url3, title: url3, selected: true}
      ])
      return

    it "リストに存在しないタブを復元しようとした場合、nullを返す", ->
      expect(tab.restoreClosed("test")).toBe(null)
      return
    return
  return
