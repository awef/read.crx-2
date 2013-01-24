describe "app.Bookmark", ->
  describe ".legacyToCurrent", ->
    it "LegacyEntryをEntryに変換する", ->
      # 板ブックマーク
      expect(app.Bookmark.legacyToCurrent(
        url: "http://__dummy.2ch.net/dummy/"
        type: "board"
        bbs_type: "2ch"
        title: "dummy"
        res_count: null
        read_state: null
        expired: false
      )).toEqual(
        url: "http://__dummy.2ch.net/dummy/"
        type: "board"
        bbsType: "2ch"
        title: "dummy"
        resCount: null
        readState: null
        expired: false
      )

      # スレブックマーク
      expect(app.Bookmark.legacyToCurrent(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: null
        read_state: null
        expired: false
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: null
        readState: null
        expired: false
      )

      # スレブックマーク（res_count）
      expect(app.Bookmark.legacyToCurrent(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: 123
        read_state: null
        expired: false
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState: null
        expired: false
      )

      # スレブックマーク（res_count + read_state）
      expect(app.Bookmark.legacyToCurrent(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: 123
        read_state:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: false
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: false
      )

      # スレブックマーク（res_count + read_state + expired）
      expect(app.Bookmark.legacyToCurrent(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: 123
        read_state:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: true
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: true
      )
      return
    return

  describe ".currentToLegacy", ->
    it "EntryをLegacyEntryに変換する", ->
      # 板ブックマーク
      expect(app.Bookmark.currentToLegacy(
        url: "http://__dummy.2ch.net/dummy/"
        type: "board"
        bbsType: "2ch"
        title: "dummy"
        resCount: null
        readState: null
        expired: false
      )).toEqual(
        url: "http://__dummy.2ch.net/dummy/"
        type: "board"
        bbs_type: "2ch"
        title: "dummy"
        res_count: null
        read_state: null
        expired: false
      )

      # スレブックマーク
      expect(app.Bookmark.currentToLegacy(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: null
        readState: null
        expired: false
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: null
        read_state: null
        expired: false
      )

      # スレブックマーク（resCount）
      expect(app.Bookmark.currentToLegacy(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState: null
        expired: false
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: 123
        read_state: null
        expired: false
      )

      # スレブックマーク（resCount + readState）
      expect(app.Bookmark.currentToLegacy(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: false
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: 123
        read_state:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: false
      )

      # スレブックマーク（resCount + readState + expired）
      expect(app.Bookmark.currentToLegacy(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: true
      )).toEqual(
        url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
        type: "thread"
        bbs_type: "2ch"
        title: "dummy"
        res_count: 123
        read_state:
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          received: 234
          read: 123
          last: 23
        expired: true
      )
      return
    return

  describe "newerEntry", ->
    describe "resCountの値が異なる場合", ->
      it "resCountが大きい方のEntryを新しいと判定する", ->
        a =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState: null
          expired: false

        b =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 124
          readState: null
          expired: false

        expect(app.Bookmark.newerEntry(a, b)).toBe(b)
        return
      return

    describe "resCountが同一の場合", ->
      it "readStateが存在する方を新しいと判定する", ->
        a =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState:
            url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
            received: 100
            read: 80
            last: 75
          expired: false

        b =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState: null
          expired: false

        expect(app.Bookmark.newerEntry(a, b)).toBe(a)
        return
      return

    describe "両方のEntryにreadStateが存在する場合", ->
      it "readの値が大きい方を新しいと判定する", ->
        a =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState:
            url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
            received: 100
            read: 80
            last: 75
          expired: false

        b =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState:
            url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
            received: 100
            read: 81
            last: 75
          expired: false

        expect(app.Bookmark.newerEntry(a, b)).toBe(b)
        return
      return

    describe "readState.readが同一だった場合", ->
      it "receivedの値が大きい方を新しいと判定する", ->
        a =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState:
            url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
            received: 100
            read: 80
            last: 75
          expired: false

        b =
          url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
          title: "dummyA"
          type: "thread"
          bbsType: "2ch"
          resCount: 123
          readState:
            url: "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/"
            received: 101
            read: 80
            last: 75
          expired: false

        expect(app.Bookmark.newerEntry(a, b)).toBe(b)
        return
      return
    return

  describe "EntryList", ->
    entry = null
    entryList = null

    beforeEach ->
      entry = {}

      entry.board0 =
        url: "http://__dummy.2ch.net/dummy/"
        type: "board"
        bbsType: "2ch"
        title: "dummy"
        resCount: null
        readState: null
        expired: false

      entry.board1 =
        url: "http://__dummy.2ch.net/dummy1/"
        type: "board"
        bbsType: "2ch"
        title: "dummy1"
        resCount: null
        readState: null
        expired: false

      entry.thread0 =
        url: "http://__dummy.2ch.net/test/read.cgi/dummy/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy"
        resCount: 123
        readState: null
        expired: true

      entry.thread1 =
        url: "http://__dummy.2ch.net/test/read.cgi/dummy/1234567891/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy1"
        resCount: 123
        readState: null
        expired: true

      entry.thread2 =
        url: "http://__dummyserver.2ch.net/test/read.cgi/dummyboard/1234567890/"
        type: "thread"
        bbsType: "2ch"
        title: "dummy2"
        resCount: 123
        readState: null
        expired: true

      entryList = new app.Bookmark.EntryList()

      for key, val of entry
        entryList.add(val)
      return

    describe "::add", ->
      it "Entryを追加する", ->
        a =
          url: "http://__dummy.2ch.net/dummy1/"
          type: "board"
          bbsType: "2ch"
          title: "dummy1"
          resCount: null
          readState: null
          expired: false

        entryList.add(a)

        expect(entryList.get(a.url)).toEqual(a)
        return
      return

    describe "::update", ->
      a = null

      beforeEach ->
        a =
          url: "http://__dummy.2ch.net/dummy2/"
          type: "board"
          bbsType: "2ch"
          title: "dummy1"
          resCount: null
          readState: null
          expired: false
        return

      it "既に格納されているEntryを更新する", ->
        entryList.add(a)

        a.title = "test"
        entryList.update(a)

        expect(entryList.get(a.url).title).toBe("test")
        return

      it "格納されていないEntryが渡された場合、無視する", ->
        a.title = "test"
        entryList.update(a)

        expect(entryList.get(a.url)).toBeNull()
        return
      return

    describe "::del", ->
      it "指定されたURLのEntryを削除する", ->
        a = {}
        for val in entryList.getAll() when val.url isnt entry.thread1.url
          a[val.url] = val

        entryList.del(entry.thread1.url)

        b = {}
        for val in entryList.getAll()
          b[val.url] = val

        expect(b).toEqual(a)
        return

      it "該当するEntryが無かった場合は何もしない", ->
        a = entryList.getAll()
        entryList.del("hogehoge")
        b = entryList.getAll()

        expect(b).toEqual(a)
        return
      return

    describe "::get", ->
      it "与えられたURLのEntryを返す", ->
        expect(entryList.get(entry.board0.url)).toEqual(entry.board0)
        expect(entryList.get(entry.thread0.url)).toEqual(entry.thread0)
        return

      it "対応するEntryが格納されていなかった場合はnullを返す", ->
        expect(entryList.get("http://__dummy.2ch.net/d_ummy/")).toBeNull()
        return
      return

    describe "::getAll", ->
      it "すべてのEntryを配列で返す", ->
        a = {}
        for val in entryList.getAll()
          a[val.url] = val

        b = {}
        for key, val of entry
          b[val.url] = val

        expect(a).toEqual(b)
        return

      it "Entryが一つも無い場合は空配列を返す", ->
        entryList.del(entry.board0.url)
        entryList.del(entry.board1.url)
        entryList.del(entry.thread0.url)
        entryList.del(entry.thread1.url)
        entryList.del(entry.thread2.url)

        expect(entryList.getAll()).toEqual([])
        return
      return

    describe "::getAllThreads", ->
      it "すべてのスレッドを配列で返す", ->
        a = {}
        for val in entryList.getAllThreads()
          a[val.url] = val

        b = {}
        for key, val of [entry.thread0, entry.thread1, entry.thread2]
          b[val.url] = val

        expect(a).toEqual(b)
        return

      it "スレッドが一つも無い場合は空配列を返す", ->
        entryList.del(entry.thread0.url)
        entryList.del(entry.thread1.url)
        entryList.del(entry.thread2.url)

        expect(entryList.getAllThreads()).toEqual([])
        return
      return

    describe "::getAllBoards", ->
      it "すべての板を配列で返す", ->
        a = {}
        for val in entryList.getAllBoards()
          a[val.url] = val

        b = {}
        for key, val of [entry.board0, entry.board1]
          b[val.url] = val

        expect(a).toEqual(b)
        return

      it "板が一つも無い場合は空配列を返す", ->
        entryList.del(entry.board0.url)
        entryList.del(entry.board1.url)

        expect(entryList.getAllBoards()).toEqual([])
        return
      return

    describe "::getThreadsByBoardURL", ->
      it "指定した板のスレッドを配列で返す", ->
        a = {}
        for val in entryList.getThreadsByBoardURL(entry.board0.url)
          a[val.url] = val

        b = {}
        for key, val of [entry.thread0, entry.thread1]
          b[val.url] = val

        expect(a).toEqual(b)
        return

      it "該当するスレッドが一つも無い場合は空配列を返す", ->
        expect(entryList.getThreadsByBoardURL(entry.board1.url)).toEqual([])
        return
      return
    return
