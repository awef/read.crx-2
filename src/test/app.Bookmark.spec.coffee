describe "app.Bookmark", ->
  dummyEntry = null
  dummyLegacyEntry = null

  beforeEach ->
    dummyEntry =
      board0:
        url: "http://__dummy.2ch.net/dummy0/"
        type: "board"
        bbsType: "2ch"
        title: "dummyboard0"
        resCount: null
        readState: null
        expired: false
      board1:
        url: "http://__dummy.2ch.net/dummy2/"
        type: "board"
        bbsType: "2ch"
        title: "dummyboard1"
        resCount: null
        readState: null
        expired: false
      thread0:
        url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummythread0"
        resCount: 123
        readState: null
        expired: false
      thread1:
        url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234568880/"
        type: "thread"
        bbsType: "2ch"
        title: "dummythread1"
        resCount: 222
        readState:
          url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234568880/"
          received: 222
          read: 200
          last: 200
        expired: false
      thread2:
        url: "http://__dummy.2ch.net/test/read.cgi/dummy1/1234567891/"
        type: "thread"
        bbsType: "2ch"
        title: "dummythread2"
        resCount: 10
        readState:
          url: "http://__dummy.2ch.net/test/read.cgi/dummy1/1234567891/"
          received: 10
          read: 10
          last: 10
        expired: true

    dummyLegacyEntry =
      board0:
        url: "http://__dummy.2ch.net/dummy0/"
        type: "board"
        bbs_type: "2ch"
        title: "dummyboard0"
        res_count: null
        read_state: null
        expired: false
      board1:
        url: "http://__dummy.2ch.net/dummy2/"
        type: "board"
        bbs_type: "2ch"
        title: "dummyboard1"
        res_count: null
        read_state: null
        expired: false
      thread0:
        url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummythread0"
        res_count: 123
        read_state: null
        expired: false
      thread1:
        url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234568880/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummythread1"
        res_count: 222
        read_state:
          url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234568880/"
          received: 222
          read: 200
          last: 200
        expired: false
      thread2:
        url: "http://__dummy.2ch.net/test/read.cgi/dummy1/1234567891/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummythread2"
        res_count: 10
        read_state:
          url: "http://__dummy.2ch.net/test/read.cgi/dummy1/1234567891/"
          received: 10
          read: 10
          last: 10
        expired: true
    return

  describe ".legacyToCurrent", ->
    it "LegacyEntryをEntryに変換する", ->
      # 板ブックマーク
      expect(app.Bookmark.legacyToCurrent(dummyLegacyEntry.board0))
        .toEqual(dummyEntry.board0)
      expect(app.Bookmark.legacyToCurrent(dummyLegacyEntry.board1))
        .toEqual(dummyEntry.board1)

      # スレブックマーク
      expect(app.Bookmark.legacyToCurrent(dummyLegacyEntry.thread0))
        .toEqual(dummyEntry.thread0)
      expect(app.Bookmark.legacyToCurrent(dummyLegacyEntry.thread1))
        .toEqual(dummyEntry.thread1)
      expect(app.Bookmark.legacyToCurrent(dummyLegacyEntry.thread2))
        .toEqual(dummyEntry.thread2)
      return
    return

  describe ".currentToLegacy", ->
    it "EntryをLegacyEntryに変換する", ->
      # 板ブックマーク
      expect(app.Bookmark.currentToLegacy(dummyEntry.board0))
        .toEqual(dummyLegacyEntry.board0)
      expect(app.Bookmark.currentToLegacy(dummyEntry.board1))
        .toEqual(dummyLegacyEntry.board1)

      # スレブックマーク
      expect(app.Bookmark.currentToLegacy(dummyEntry.thread0))
        .toEqual(dummyLegacyEntry.thread0)
      expect(app.Bookmark.currentToLegacy(dummyEntry.thread1))
        .toEqual(dummyLegacyEntry.thread1)
      expect(app.Bookmark.currentToLegacy(dummyEntry.thread2))
        .toEqual(dummyLegacyEntry.thread2)
      return
    return

  describe "newerEntry", ->
    describe "resCountの値が異なる場合", ->
      it "resCountが大きい方のEntryを新しいと判定する", ->
        a = dummyEntry.thread0
        b = app.deepCopy(a)
        b.resCount++

        expect(app.Bookmark.newerEntry(a, b)).toBe(b)
        return
      return

    describe "resCountが同一の場合", ->
      it "readStateが存在する方を新しいと判定する", ->
        a = dummyEntry.thread1
        b = app.deepCopy(a)
        b.readState = null

        expect(app.Bookmark.newerEntry(a, b)).toBe(a)
        return
      return

    describe "両方のEntryにreadStateが存在する場合", ->
      it "readの値が大きい方を新しいと判定する", ->
        a = dummyEntry.thread1
        b = app.deepCopy(a)
        b.readState.read++

        expect(app.Bookmark.newerEntry(a, b)).toBe(b)
        return
      return

    describe "readState.readが同一だった場合", ->
      it "receivedの値が大きい方を新しいと判定する", ->
        a = dummyEntry.thread1
        b = app.deepCopy(a)
        b.readState.received++

        expect(app.Bookmark.newerEntry(a, b)).toBe(b)
        return
      return

    describe "どちらが新しいか判定出来ない場合", ->
      it "nullを返す", ->
        a = dummyEntry.board0
        b = dummyEntry.board1
        expect(app.Bookmark.newerEntry(a, b)).toBeNull()

        a = dummyEntry.thread0
        b = dummyEntry.thread0
        expect(app.Bookmark.newerEntry(a, b)).toBeNull()

        a = dummyEntry.thread1
        b = dummyEntry.thread1
        expect(app.Bookmark.newerEntry(a, b)).toBeNull()

        a = dummyEntry.thread2
        b = dummyEntry.thread2
        expect(app.Bookmark.newerEntry(a, b)).toBeNull()
        return
      return
    return

  describe "EntryList", ->
    entryList = null

    beforeEach ->
      entryList = new app.Bookmark.EntryList()

      for key, entry of dummyEntry
        entryList.add(entry)
      return

    describe "::add", ->
      it "Entryを追加する", ->
        dummy = app.deepCopy(dummyEntry.board0)
        dummy.url = "http://__dummy.2ch.net/___/"

        entryList.add(dummy)

        expect(entryList.get(dummy.url)).toEqual(dummy)
        return
      return

    describe "::update", ->
      it "既に格納されているEntryを更新する", ->
        entryList.add(dummyEntry.board0)

        dummyEntry.board0.title = "test"
        entryList.update(dummyEntry.board0)

        expect(entryList.get(dummyEntry.board0.url).title).toBe("test")
        return

      it "格納されていないEntryが渡された場合、無視する", ->
        dummy = app.deepCopy(dummyEntry.board0)
        dummy.url = "http://__dummy.2ch.net/___/"
        dummy.title = "test"
        entryList.update(dummy)

        expect(entryList.get(dummy.url)).toBeNull()
        return
      return

    describe "::del", ->
      it "指定されたURLのEntryを削除する", ->
        entryList.del(dummyEntry.thread0.url)

        expect(entryList.get(dummyEntry.thread0.url)).toBeNull()
        return

      it "該当するEntryが無かった場合は何もしない", ->
        a = entryList.getAll()
        entryList.del("hogehoge")
        b = entryList.getAll()

        expect(b).toEqual(a)
        return
      return

    describe "::import", ->
      it "thisに存在しないエントリを全てthisに追加する", ->
        a = new app.Bookmark.EntryList()
        a.add(dummyEntry.board0)
        a.add(dummyEntry.thread0)

        b = new app.Bookmark.EntryList()
        b.add(dummyEntry.board0)
        b.add(dummyEntry.board1)
        b.add(dummyEntry.thread0)
        b.add(dummyEntry.thread1)

        a.import(b)

        expect(a.get(dummyEntry.board0.url)).toEqual(dummyEntry.board0)
        expect(a.get(dummyEntry.board1.url)).toEqual(dummyEntry.board1)
        expect(a.get(dummyEntry.thread0.url)).toEqual(dummyEntry.thread0)
        expect(a.get(dummyEntry.thread1.url)).toEqual(dummyEntry.thread1)
        return

      it "thisに存在するエントリの場合、より新しいと判断した場合のみ上書きする", ->
        a = new app.Bookmark.EntryList()
        a.add(dummyEntry.thread0)
        a.add(dummyEntry.thread1)

        b = new app.Bookmark.EntryList()
        dummyEntry.thread0.resCount--
        dummyEntry.thread1.resCount++
        b.add(dummyEntry.thread0)
        b.add(dummyEntry.thread1)

        a.import(b)

        expect(a.get(dummyEntry.thread0.url)).not.toEqual(dummyEntry.thread0)
        expect(a.get(dummyEntry.thread1.url)).toEqual(dummyEntry.thread1)
        return
      return

    describe "::get", ->
      it "与えられたURLのEntryを返す", ->
        expect(entryList.get(dummyEntry.board0.url))
          .toEqual(dummyEntry.board0)
        expect(entryList.get(dummyEntry.thread0.url))
          .toEqual(dummyEntry.thread0)
        return

      it "対応するEntryが格納されていなかった場合はnullを返す", ->
        expect(entryList.get("http://__dummy.2ch.net/d_ummy/")).toBeNull()
        return
      return

    describe "::getAll", ->
      it "すべてのEntryを配列で返す", ->
        a = {}
        for entry in entryList.getAll()
          a[entry.url] = entry

        b = {}
        for key, entry of dummyEntry
          b[entry.url] = entry

        expect(a).toEqual(b)
        return

      it "Entryが一つも無い場合は空配列を返す", ->
        for url in (entry.url for key, entry of dummyEntry)
          entryList.del(url)

        expect(entryList.getAll()).toEqual([])
        return
      return

    describe "::getAllThreads", ->
      it "すべてのスレッドを配列で返す", ->
        a = {}
        for entry in entryList.getAllThreads()
          a[entry.url] = entry

        b = {}
        for key, entry of dummyEntry when entry.type is "thread"
          b[entry.url] = entry

        expect(a).toEqual(b)
        return

      it "スレッドが一つも無い場合は空配列を返す", ->
        for url in (entry.url for key, entry of dummyEntry when entry.type is "thread")
          entryList.del(url)

        expect(entryList.getAllThreads()).toEqual([])
        return
      return

    describe "::getAllBoards", ->
      it "すべての板を配列で返す", ->
        a = {}
        for entry in entryList.getAllBoards()
          a[entry.url] = entry

        b = {}
        for key, entry of dummyEntry when entry.type is "board"
          b[entry.url] = entry

        expect(a).toEqual(b)
        return

      it "板が一つも無い場合は空配列を返す", ->
        for url in (entry.url for key, entry of dummyEntry when entry.type is "board")
          entryList.del(url)

        expect(entryList.getAllBoards()).toEqual([])
        return
      return

    describe "::getThreadsByBoardURL", ->
      it "指定した板のスレッドを配列で返す", ->
        a = {}
        for entry in entryList.getThreadsByBoardURL(dummyEntry.board0.url)
          a[entry.url] = entry

        b = {}
        for key, entry of [dummyEntry.thread0, dummyEntry.thread1]
          b[entry.url] = entry

        expect(a).toEqual(b)
        return

      it "該当するスレッドが一つも無い場合は空配列を返す", ->
        expect(entryList.getThreadsByBoardURL(dummyEntry.board1.url)).toEqual([])
        return
      return
    return

  describe "SyncableEntryList", ->
    entryList = null
    listA = null
    listB = null

    beforeEach ->
      entryList = new app.Bookmark.SyncableEntryList()
      listA = new app.Bookmark.SyncableEntryList()
      listB = new app.Bookmark.SyncableEntryList()
      return

    describe ".onChanged", ->
      spy = null

      beforeEach ->
        spy = jasmine.createSpy("onChanged")
        return

      it "ブックマーク追加時にcallされる", ->
        entryList.onChanged.add(spy)

        entryList.add(dummyEntry.board0)

        expect(spy.callCount).toBe(1)
        expect(spy).toHaveBeenCalledWith
          type: "ADD"
          entry: dummyEntry.board0
        return

      it "ブックマーク変更時にcallされる(title)", ->
        entryList.add(dummyEntry.board0)
        entryList.onChanged.add(spy)

        dummyEntry.board0.title += "_test"
        entryList.update(dummyEntry.board0)

        expect(spy.callCount).toBe(1)
        expect(spy).toHaveBeenCalledWith
          type: "TITLE"
          entry: dummyEntry.board0
        return

      it "ブックマーク変更時にcallされる(resCount)", ->
        entryList.add(dummyEntry.thread0)
        entryList.onChanged.add(spy)

        dummyEntry.thread0.resCount++
        entryList.update(dummyEntry.thread0)

        expect(spy.callCount).toBe(1)
        expect(spy).toHaveBeenCalledWith
          type: "RES_COUNT"
          entry: dummyEntry.thread0
        return

      it "ブックマーク変更時にcallされる(readState)", ->
        entryA = app.deepCopy(dummyEntry.thread1)
        entryA.readState = null
        entryB = dummyEntry.thread1

        entryList.add(entryA)
        entryList.onChanged.add(spy)

        entryList.update(entryB)

        expect(spy.callCount).toBe(1)
        expect(spy).toHaveBeenCalledWith
          type: "READ_STATE"
          entry: entryB
        return

      it "ブックマーク変更時にcallされる(expired)", ->
        entryList.add(dummyEntry.thread0)
        entryList.onChanged.add(spy)

        dummyEntry.thread0.expired = true
        entryList.update(dummyEntry.thread0)

        expect(spy.callCount).toBe(1)
        expect(spy).toHaveBeenCalledWith
          type: "EXPIRED"
          entry: dummyEntry.thread0
        return

      it "複数の項目が変更された場合は複数回callされる", ->
        entryList.add(dummyEntry.thread0)
        entryList.onChanged.add(spy)

        dummyEntry.thread0.title += "_test"
        dummyEntry.thread0.resCount++
        dummyEntry.thread0.readState =
          received: 1
          read: 1
          last: 1
        dummyEntry.thread0.expired = true

        entryList.update(dummyEntry.thread0)

        expect(spy.callCount).toBe(4)
        expect(spy).toHaveBeenCalledWith
          type: "TITLE"
          entry: dummyEntry.thread0
        expect(spy).toHaveBeenCalledWith
          type: "RES_COUNT"
          entry: dummyEntry.thread0
        expect(spy).toHaveBeenCalledWith
          type: "READ_STATE"
          entry: dummyEntry.thread0
        expect(spy).toHaveBeenCalledWith
          type: "EXPIRED"
          entry: dummyEntry.thread0
        return

      it "ブックマーク削除時にcallされる", ->
        entryList.add(dummyEntry.board0)
        entryList.onChanged.add(spy)

        entryList.del(dummyEntry.board0.url)

        expect(spy.callCount).toBe(1)
        expect(spy).toHaveBeenCalledWith
          type: "DEL"
          entry: dummyEntry.board0
        return
      return

    describe "manipulateByBookmarkUpdateEvent", ->
      it "BoomkarkUpdateEventから、同等の操作を実行する(ADD)", ->
        dummyEvent =
          type: "ADD"
          entry: dummyEntry.board0

        spyOn(entryList, "add")
        entryList.manipulateByBookmarkUpdateEvent(dummyEvent)

        expect(entryList.add.callCount).toBe(1)
        expect(entryList.add).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "BoomkarkUpdateEventから、同等の操作を実行する(TITLE)", ->
        dummyEvent =
          type: "TITLE"
          entry: dummyEntry.board0

        spyOn(entryList, "update")
        entryList.manipulateByBookmarkUpdateEvent(dummyEvent)

        expect(entryList.update.callCount).toBe(1)
        expect(entryList.update).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "BoomkarkUpdateEventから、同等の操作を実行する(RES_COUNT)", ->
        dummyEvent =
          type: "RES_COUNT"
          entry: dummyEntry.board0

        spyOn(entryList, "update")
        entryList.manipulateByBookmarkUpdateEvent(dummyEvent)

        expect(entryList.update.callCount).toBe(1)
        expect(entryList.update).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "BoomkarkUpdateEventから、同等の操作を実行する(READ_STATE)", ->
        dummyEvent =
          type: "READ_STATE"
          entry: dummyEntry.thread0

        spyOn(entryList, "update")
        entryList.manipulateByBookmarkUpdateEvent(dummyEvent)

        expect(entryList.update.callCount).toBe(1)
        expect(entryList.update).toHaveBeenCalledWith(dummyEntry.thread0)
        return

      it "BoomkarkUpdateEventから、同等の操作を実行する(EXPIRED)", ->
        dummyEvent =
          type: "EXPIRED"
          entry: dummyEntry.board0

        spyOn(entryList, "update")
        entryList.manipulateByBookmarkUpdateEvent(dummyEvent)

        expect(entryList.update.callCount).toBe(1)
        expect(entryList.update).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "BoomkarkUpdateEventから、同等の操作を実行する(DEL)", ->
        dummyEvent =
          type: "DEL"
          entry: dummyEntry.board0

        spyOn(entryList, "del")
        entryList.manipulateByBookmarkUpdateEvent(dummyEvent)

        expect(entryList.del.callCount).toBe(1)
        expect(entryList.del).toHaveBeenCalledWith(dummyEntry.board0.url)
        return
      return

    describe "followDeletion", ->
      it "相手のEntryListに存在しないEntryを削除する", ->
        listA.add(dummyEntry.board0)
        listA.add(dummyEntry.board1)
        listA.add(dummyEntry.thread0)
        listA.add(dummyEntry.thread1)

        listB.add(dummyEntry.board0)
        listB.add(dummyEntry.thread0)

        spyOn(listA, "del")
        listA.followDeletion(listB)

        expect(listA.del.callCount).toBe(2)
        expect(listA.del).toHaveBeenCalledWith(dummyEntry.board1.url)
        expect(listA.del).toHaveBeenCalledWith(dummyEntry.thread1.url)
        return
      return

    describe "syncStart", ->
      it "同期開始処理を実行する", ->
        spyOn(listA, "import")
        spyOn(listA, "followDeletion")
        spyOn(listA, "syncResume").andCallThrough()
        spyOn(listB, "import")
        spyOn(listB, "followDeletion")
        spyOn(listB, "syncResume")

        listA.syncStart(listB)

        expect(listA.import.callCount).toBe(1)
        expect(listA.followDeletion.callCount).toBe(1)
        expect(listA.syncResume.callCount).toBe(1)
        expect(listA.syncResume).toHaveBeenCalledWith(listB)
        expect(listB.import.callCount).toBe(1)
        expect(listB.followDeletion).not.toHaveBeenCalled()
        expect(listB.syncResume).not.toHaveBeenCalled()
        return
      return

    describe "syncResume", ->
      it "同期再開処理を実行する", ->
        spyOn(listA, "import")
        spyOn(listA, "followDeletion")
        spyOn(listA.onChanged, "add")
        spyOn(listB, "import")
        spyOn(listB, "followDeletion")
        spyOn(listB.onChanged, "add")

        listA.syncResume(listB)

        expect(listA.import.callCount).toBe(1)
        expect(listA.followDeletion.callCount).toBe(1)
        expect(listA.onChanged.add.callCount).toBe(1)
        expect(listA.onChanged.add).toHaveBeenCalledWith(listB.observerForSync)
        expect(listB.import).not.toHaveBeenCalled()
        expect(listB.followDeletion).not.toHaveBeenCalled()
        expect(listB.onChanged.add.callCount).toBe(1)
        expect(listB.onChanged.add).toHaveBeenCalledWith(listA.observerForSync)
        return

      it "同期中は同期対象の変更をコピーする(ADD)", ->
        listA.syncResume(listB)

        spyOn(listA, "add")

        listB.add(dummyEntry.board0)

        expect(listA.add.callCount).toBe(1)
        expect(listA.add).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "同期中は同期対象の変更をコピーする(TITLE)", ->
        listA.syncResume(listB)

        spyOn(listA, "update")

        listB.add(dummyEntry.board0)
        dummyEntry.board0.title += "_modified"
        listB.update(dummyEntry.board0)

        expect(listA.update.callCount).toBe(1)
        expect(listA.update).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "同期中は同期対象の変更をコピーする(RES_COUNT)", ->
        listA.syncResume(listB)

        spyOn(listA, "update")

        listB.add(dummyEntry.thread0)
        dummyEntry.thread0.resCount++
        listB.update(dummyEntry.thread0)

        expect(listA.update.callCount).toBe(1)
        expect(listA.update).toHaveBeenCalledWith(dummyEntry.thread0)
        return

      it "同期中は同期対象の変更をコピーする(READ_STATE)", ->
        listA.syncResume(listB)

        spyOn(listA, "update")

        listB.add(dummyEntry.thread1)
        dummyEntry.thread1.readState.last++
        listB.update(dummyEntry.thread1)

        expect(listA.update.callCount).toBe(1)
        expect(listA.update).toHaveBeenCalledWith(dummyEntry.thread1)
        return

      it "同期中は同期対象の変更をコピーする(EXPIRED)", ->
        listA.syncResume(listB)

        spyOn(listA, "update")

        listB.add(dummyEntry.thread0)
        dummyEntry.thread0.expired = true
        listB.update(dummyEntry.thread0)

        expect(listA.update.callCount).toBe(1)
        expect(listA.update).toHaveBeenCalledWith(dummyEntry.thread0)
        return

      it "同期中は同期対象の変更をコピーする(DEL)", ->
        listA.syncResume(listB)

        spyOn(listA, "del")

        listB.add(dummyEntry.board0)
        listB.del(dummyEntry.board0.url)

        expect(listA.del.callCount).toBe(1)
        expect(listA.del).toHaveBeenCalledWith(dummyEntry.board0.url)
        return

      it "同期中は同期対象へ変更をコピーする(ADD)", ->
        listA.syncResume(listB)

        spyOn(listB, "add")

        listA.add(dummyEntry.board0)

        expect(listB.add.callCount).toBe(1)
        expect(listB.add).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "同期中は同期対象へ変更をコピーする(TITLE)", ->
        listA.syncResume(listB)

        spyOn(listB, "update")

        listA.add(dummyEntry.board0)
        dummyEntry.board0.title += "_modified"
        listA.update(dummyEntry.board0)

        expect(listB.update.callCount).toBe(1)
        expect(listB.update).toHaveBeenCalledWith(dummyEntry.board0)
        return

      it "同期中は同期対象へ変更をコピーする(RES_COUNT)", ->
        listA.syncResume(listB)

        spyOn(listB, "update")

        listA.add(dummyEntry.thread0)
        dummyEntry.thread0.resCount++
        listA.update(dummyEntry.thread0)

        expect(listB.update.callCount).toBe(1)
        expect(listB.update).toHaveBeenCalledWith(dummyEntry.thread0)
        return

      it "同期中は同期対象へ変更をコピーする(READ_STATE)", ->
        listA.syncResume(listB)

        spyOn(listB, "update")

        listA.add(dummyEntry.thread1)
        dummyEntry.thread1.readState.last++
        listA.update(dummyEntry.thread1)

        expect(listB.update.callCount).toBe(1)
        expect(listB.update).toHaveBeenCalledWith(dummyEntry.thread1)
        return

      it "同期中は同期対象へ変更をコピーする(EXPIRED)", ->
        listA.syncResume(listB)

        spyOn(listB, "update")

        listA.add(dummyEntry.thread0)
        dummyEntry.thread0.expired = true
        listA.update(dummyEntry.thread0)

        expect(listB.update.callCount).toBe(1)
        expect(listB.update).toHaveBeenCalledWith(dummyEntry.thread0)
        return

      it "同期中は同期対象へ変更をコピーする(DEL)", ->
        listA.syncResume(listB)

        spyOn(listB, "del")

        listA.add(dummyEntry.board0)
        listA.del(dummyEntry.board0.url)

        expect(listB.del.callCount).toBe(1)
        expect(listB.del).toHaveBeenCalledWith(dummyEntry.board0.url)
        return
      return

    describe "syncStop", ->
      it "同期終了処理を実行する", ->
        spyOn(listA.onChanged, "remove")
        spyOn(listB.onChanged, "remove")

        listA.syncStop(listB)

        expect(listA.onChanged.remove.callCount).toBe(1)
        expect(listA.onChanged.remove).toHaveBeenCalledWith(listB.observerForSync)
        expect(listB.onChanged.remove.callCount).toBe(1)
        expect(listB.onChanged.remove).toHaveBeenCalledWith(listA.observerForSync)
        return

      it "同期終了後は同期対象の変更をコピーしない", ->
        listA.syncResume(listB)
        listA.syncStop(listB)

        spyOn(listA, "add")
        spyOn(listA, "update")
        spyOn(listA, "del")

        listB.add(dummyEntry.thread0)
        dummyEntry.thread0.title += "_modified"
        dummyEntry.thread0.resCount++
        dummyEntry.thread0.expired = true
        listB.update(dummyEntry.thread0)
        listB.del(dummyEntry.thread0.url)

        expect(listA.add).not.toHaveBeenCalled()
        expect(listA.update).not.toHaveBeenCalled()
        expect(listA.del).not.toHaveBeenCalled()
        return

      it "同期終了後は同期対象へ変更をコピーしない", ->
        listA.syncResume(listB)
        listA.syncStop(listB)

        spyOn(listB, "add")
        spyOn(listB, "update")
        spyOn(listB, "del")

        listA.add(dummyEntry.thread0)
        dummyEntry.thread0.title += "_modified"
        dummyEntry.thread0.resCount++
        dummyEntry.thread0.expired = true
        listA.update(dummyEntry.thread0)
        listA.del(dummyEntry.thread0.url)

        expect(listB.add).not.toHaveBeenCalled()
        expect(listB.update).not.toHaveBeenCalled()
        expect(listB.del).not.toHaveBeenCalled()
        return
      return
    return
  return
