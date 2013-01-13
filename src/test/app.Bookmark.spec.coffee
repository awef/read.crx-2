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
