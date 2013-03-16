describe "app.Bookmark.WebSQLEntryList", ->
  "use strict"

  TEST_DB_NAME = "TESTWebSQLEntryList"
  db = openDatabase(TEST_DB_NAME, "", "WebSQLEntryList", 0)
  wsel = null

  createTable = ->
    $.Deferred((d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql("""
            CREATE TABLE EntryList(
              url TEXT NOT NULL PRIMARY KEY,
              title TEXT NOT NULL,
              type TEXT NOT NULL,
              bbsType TEXT NOT NULL,
              resCount INTEGER,
              expired INTEGER NOT NULL,
              readState_received INTEGER,
              readState_read INTEGER,
              readState_last INTEGER
            )
          """)
          return
        ->
          d.reject()
          return
        ->
          d.resolve()
          return
      )
    ).promise()

  insertDummyEntry = ->
    $.Deferred((d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql(
            "INSERT INTO EntryList values(?, ?, ?, ?, ?, ?, ?, ?, ?)"
            [
              "http://__dummy.2ch.net/dummy0/",
              "dummyBoard0",
              "board",
              "2ch",
              null,
              0,
              null,
              null,
              null
            ]
          )
          transaction.executeSql(
            "INSERT INTO EntryList values(?, ?, ?, ?, ?, ?, ?, ?, ?)"
            [
              "http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/",
              "dummyThread0",
              "thread",
              "2ch",
              123,
              1,
              120,
              110,
              105
            ]
          )
          return
        ->
          d.reject()
          return
        ->
          d.resolve()
          return
      )
    ).promise()

  dropTable = ->
    $.Deferred((d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql("DROP TABLE IF EXISTS EntryList")
          return
        ->
          d.reject()
          return
        ->
          d.resolve()
          return
      )
    ).promise()

  afterEach ->
    # onReadyDBが呼ばれるまで待機する
    # （it終了後にopenDBのCREATE TABLEが走るのを防ぐため）
    if wsel
      onReadyDB = jasmine.createSpy("onReadyDB")
      wsel.readyDB.add(onReadyDB)

      waitsFor ->
        onReadyDB.wasCalled
    return

  describe "インスタンス生成時", ->
    it "::openDBを実行する", ->
      spyOn(app.Bookmark.WebSQLEntryList::, "openDB")

      wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)

      expect(app.Bookmark.WebSQLEntryList::openDB.callCount).toBe(1)

      wsel = null
      return

    it "::loadFromDBを実行する", ->
      onDBReady = jasmine.createSpy("onDBReady")
      wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)

      spyOn(wsel, "loadFromDB")
      wsel.readyDB.add(onDBReady)

      waitsFor ->
        onDBReady.wasCalled

      runs ->
        expect(wsel.loadFromDB.callCount).toBe(1)
        return
      return
    return

  describe "entryListに変更が加えられた場合", ->
    it "DBにも即座に変更を加える", ->
      wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)

      onReady = jasmine.createSpy("onReady")
      wsel.ready.add(onReady)

      dummyEntry =
        url: "http://__dummy.2ch.net/dummy1/"
        type: "board"
        title: "dummyboard0"
        resCount: null
        readState: null
        expired: false

      waitsFor ->
        onReady.wasCalled

      runs ->
        spyOn(wsel, "putToDB")
        spyOn(wsel, "deleteFromDB")

        wsel.add(dummyEntry)

        expect(wsel.putToDB.callCount).toBe(1)
        expect(wsel.putToDB).toHaveBeenCalledWith(dummyEntry)

        dummyEntry.title += "_modified"
        wsel.update(dummyEntry)

        expect(wsel.putToDB.callCount).toBe(2)
        expect(wsel.putToDB).toHaveBeenCalledWith(dummyEntry)

        wsel.remove(dummyEntry.url)

        expect(wsel.deleteFromDB.callCount).toBe(1)
        expect(wsel.deleteFromDB).toHaveBeenCalledWith(dummyEntry.url)
        return
      return
    return

  describe "::openDB", ->
    describe "DBがなかった場合", ->
      it "DBを初期化する", ->
        onReadyDB = jasmine.createSpy("onReadyDB")
        insertDummy = null

        preparing = dropTable()

        waitsFor ->
          preparing.state() is "resolved"

        runs ->
          wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)
          wsel.readyDB.add(onReadyDB)
          return

        waitsFor ->
          onReadyDB.wasCalled

        runs ->
          insertDummy = insertDummyEntry()
          return

        waitsFor ->
          insertDummy.state() is "resolved"

        runs ->
          expect(insertDummy.state()).toBe("resolved")
          return
        return
      return
    return

  describe "::loadFromDB", ->
    it "DBからデータを読み取る", ->
      preparing = (
        dropTable()
          .pipe ->
            createTable()
          .pipe ->
            insertDummyEntry()
      )

      onReady = jasmine.createSpy("onReady")

      waitsFor ->
        preparing.state() is "resolved"

      runs ->
        wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)
        wsel.ready.add(onReady)
        return

      waitsFor ->
        onReady.wasCalled

      runs ->
        expect(wsel.get("http://__dummy.2ch.net/dummy0/")).toEqual
          url: "http://__dummy.2ch.net/dummy0/"
          type: "board"
          bbsType: "2ch"
          title: "dummyBoard0"
          resCount: null
          readState: null
          expired: false

        expect(wsel.get("http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/")).toEqual
          url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/"
          type: "thread"
          bbsType: "2ch"
          title: "dummyThread0"
          resCount: 123
          readState:
            url: "http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/",
            received: 120
            read: 110
            last: 105
          expired: true
        return
      return
    return

  describe "::putToDB", ->
    it "DBにEntryを追加する", ->
      preparing = dropTable()
      putCallback = jasmine.createSpy("putCallback")
      result = null

      dummyEntry =
        url: "http://__dummy.2ch.net/dummy0/"
        type: "board"
        bbsType: "2ch"
        title: "dummyBoard0"
        resCount: null
        readState: null
        expired: false

      waitsFor ->
        preparing.state() is "resolved"

      runs ->
        wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)
        wsel.putToDB(dummyEntry, putCallback)
        return

      waitsFor ->
        putCallback.wasCalled

      runs ->
        db.transaction (transaction) ->
          transaction.executeSql(
            "SELECT * FROM EntryList"
            []
            (transaction, _result) ->
              result = _result
              return
          )
        return

      waitsFor ->
        result isnt null

      runs ->
        expect(result.rows.item(0)).toEqual
          url: dummyEntry.url
          title: dummyEntry.title
          type: dummyEntry.type
          bbsType: dummyEntry.bbsType
          resCount: dummyEntry.resCount
          expired: 0
          readState_received: null
          readState_read: null
          readState_last: null
        return
      return

    it "DBのEntryを更新する", ->
      preparing = dropTable()
      putCallback = jasmine.createSpy("putCallback")
      putCallback2 = jasmine.createSpy("putCallback2")
      result = null

      dummyEntry =
        url: "http://__dummy.2ch.net/dummy0/"
        type: "board"
        bbsType: "2ch"
        title: "dummyBoard0-modified"
        resCount: null
        readState: null
        expired: false

      waitsFor ->
        preparing.state() is "resolved"

      runs ->
        wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)
        wsel.putToDB(dummyEntry, putCallback)
        return

      waitsFor ->
        putCallback.wasCalled

      runs ->
        dummyEntry.title += "-modified"
        wsel.putToDB(dummyEntry, putCallback2)
        return

      waitsFor ->
        putCallback2.wasCalled

      runs ->
        db.transaction (transaction) ->
          transaction.executeSql(
            "SELECT * FROM EntryList"
            []
            (transaction, _result) ->
              result = _result
              return
          )
        return

      waitsFor ->
        result isnt null

      runs ->
        expect(result.rows.item(0)).toEqual
          url: dummyEntry.url
          title: dummyEntry.title
          type: dummyEntry.type
          bbsType: dummyEntry.bbsType
          resCount: dummyEntry.resCount
          expired: 0
          readState_received: null
          readState_read: null
          readState_last: null
        return
      return
    return

  describe "::deleteFromDB", ->
    it "DBからEntryを削除する", ->
      preparing = (
        dropTable()
          .pipe ->
            createTable()
          .pipe ->
            insertDummyEntry()
      )
      deleteCallback = jasmine.createSpy("deleteCallback")
      deleteCallback2 = jasmine.createSpy("deleteCallback2")
      result = null

      waitsFor ->
        preparing.state() is "resolved"

      runs ->
        wsel = new app.Bookmark.WebSQLEntryList(TEST_DB_NAME)
        wsel.deleteFromDB("http://__dummy.2ch.net/dummy0/", deleteCallback)
        wsel.deleteFromDB("http://__dummy.2ch.net/test/read.cgi/dummy0/1234567890/", deleteCallback2)
        return

      waitsFor ->
        deleteCallback.wasCalled and deleteCallback2.wasCalled

      runs ->
        db.transaction (transaction) ->
          transaction.executeSql(
            "SELECT * FROM EntryList"
            []
            (transaction, _result) ->
              result = _result
              return
          )
        return

      waitsFor ->
        result isnt null

      runs ->
        expect(result.rows.length).toBe(0)
        return
      return
    return
  return
