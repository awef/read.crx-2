describe "UI.ThreadList", ->
  table = null

  dummyURL0 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
  dummyURL1 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567891/"
  dummyURL2 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567892/"

  beforeEach ->
    table = document.createElement("table")
    return

  it "指定された表示項目に合わせてtheadを生成する（/view/board.html相当）", ->
    threadList = new UI.ThreadList(table,
      th: ["title", "res", "unread", "heat", "createdDate"])

    expect(table.querySelector("thead").innerHTML).toBe(
      """
      <tr>
        <th class="title">タイトル</th>
        <th class="res">レス数</th>
        <th class="unread">未読数</th>
        <th class="heat">勢い</th>
        <th class="created_date">作成日時</th>
      </tr>
      """.replace(/(?:  |\n)/g, "")
    )
    return

  it "指定された表示項目に合わせてtheadを生成する（/view/bookmark.html相当）", ->
    threadList = new UI.ThreadList(table,
      th: ["title", "res", "unread", "heat", "createdDate"])

    expect(table.querySelector("thead").innerHTML).toBe(
      """
      <tr>
        <th class="title">タイトル</th>
        <th class="res">レス数</th>
        <th class="unread">未読数</th>
        <th class="heat">勢い</th>
        <th class="created_date">作成日時</th>
      </tr>
      """.replace(/(?:  |\n)/g, "")
    )
    return

  it "指定された表示項目に合わせてtheadを生成する（/view/history.html相当）", ->
    threadList = new UI.ThreadList(table, th: ["title", "viewedDate"])

    expect(table.querySelector("thead").innerHTML).toBe(
      """
      <tr>
        <th class="title">タイトル</th>
        <th class="viewed_date">閲覧日時</th>
      </tr>
      """.replace(/(?:  |\n)/g, "")
    )
    return

  it "指定された表示項目に合わせてtheadを生成する（/view/search.html相当）", ->
    threadList = new UI.ThreadList(table,
      th: ["bookmark", "title", "boardTitle", "res", "heat", "createdDate"])

    expect(table.querySelector("thead").innerHTML).toBe(
      """
      <tr>
        <th class="bookmark">★</th>
        <th class="title">タイトル</th>
        <th class="board_title">板名</th>
        <th class="res">レス数</th>
        <th class="heat">勢い</th>
        <th class="created_date">作成日時</th>
      </tr>
      """.replace(/(?:  |\n)/g, "")
    )
    return

  it "bookmark_udpatedメッセージを受けてブックマーク表示を更新する", ->
    threadList = new UI.ThreadList(table, th: ["bookmark"])
    threadList.addItem(url: dummyURL0, title: "dummy0")
    td = table.querySelector("td:first-child")

    dummyBookmark =
      url: dummyURL0
      title: "dummy0"
      type: "thread"
      bbs_type: "2ch"
      res_count: 10
      expired: false
      read_state: null

    expect(td.textContent).toBe("")

    app.message.send("bookmark_updated", {
      type: "added"
      bookmark: dummyBookmark
    })

    waitsFor -> td.textContent is "★"

    runs ->
      expect(td.textContent).toBe("★")
      return

    runs ->
      app.message.send("bookmark_updated", {
        type: "removed"
        bookmark: dummyBookmark
      })
      return

    waitsFor -> td.textContent is ""

    runs ->
      expect(td.textContent).toBe("")
      return
    return

  it "bookmark_udpatedメッセージを受けてスレッドを追加/削除する", ->
    threadList = new UI.ThreadList(table, th: ["title"], bookmarkAddRm: true)
    dummyBookmark =
      url: dummyURL0
      title: "dummy0"
      type: "thread"
      bbs_type: "2ch"
      res_count: 10
      expired: false
      read_state: null

    expect(table.querySelector("tr[data-href=\"#{dummyURL0}\"]")).toBeNull()

    app.message.send("bookmark_updated", {
      type: "added"
      bookmark: dummyBookmark
    })

    waitsFor ->
      table.querySelector("tr[data-href=\"#{dummyURL0}\"]") isnt null

    runs ->
      expect(table.querySelector("tr[data-href=\"#{dummyURL0}\"]")).not.toBeNull()
      return

    runs ->
      app.message.send("bookmark_updated", {
        type: "removed"
        bookmark: dummyBookmark
      })
      return

    waitsFor ->
      table.querySelector("tr[data-href=\"#{dummyURL0}\"]") is null

    runs ->
      expect(table.querySelector("tr[data-href=\"#{dummyURL0}\"]")).toBeNull()
      return
    return

  it "bookmark_updated(res_count)メッセージを受けてレス数/未読数表示を更新する", ->
    threadList = new UI.ThreadList(table, th: ["res", "unread"])
    threadList.addItem(url: dummyURL0, title: "dummy0")
    res = table.querySelector("td:first-child")
    unread = table.querySelector("td:nth-child(2)")

    dummyBookmark =
      url: dummyURL0
      title: "dummy0"
      type: "thread"
      bbs_type: "2ch"
      res_count: 10
      expired: false
      read_state: null

    expect(res.textContent).toBe("")
    expect(unread.textContent).toBe("")

    app.message.send("bookmark_updated", {
      type: "res_count"
      bookmark: dummyBookmark
    })

    waitsFor -> unread.textContent is "10"

    runs ->
      expect(res.textContent).toBe("10")
      expect(unread.textContent).toBe("10")
      return
    return

  it "read_state_updatedメッセージを受けて未読数表示を更新する", ->
    threadList = new UI.ThreadList(table, th: ["res", "unread"])
    threadList.addItem(url: dummyURL0, title: "dummy0")

    res = table.querySelector("td:first-child")
    unread = table.querySelector("td:nth-child(2)")

    expect(unread.textContent).toBe("")

    res.textContent = "5"

    app.message.send("read_state_updated", {
      board_url: app.url.thread_to_board(dummyURL0)
      read_state: {
        url: dummyURL0
        last: 1
        read: 2
        received: 4
      }
    })

    waitsFor ->
      unread.textContent isnt ""

    runs ->
      expect(unread.textContent).toBe("3")
      return
    return

  describe "::addItem", ->
    now = Date.now()

    it "スレのデータからDOMを構築する（/view/board.html相当）", ->
      items = [
        {
          title: "dummy0"
          url: dummyURL0
          res_count: 123
          created_at: 1234567890 * 1000
          read_state: {
            url: dummyURL0
            read: 50
            received: 50
            last: 50
          }
          thread_number: 0
        }
        {
          title: "dummy1"
          url: dummyURL1
          res_count: 0
          created_at: 1234567891 * 1000
          read_state: {
            url: dummyURL1
            read: 0
            received: 0
            last: 0
          }
          thread_number: 1
        }
        {
          title: "dummy2"
          url: dummyURL2
          res_count: 12
          created_at: 1234567892 * 1000
          read_state: {
            url: dummyURL2
            read: 12
            received: 12
            last: 12
          }
          thread_number: 2
        }
      ]

      threadList = new UI.ThreadList(table,
        th: ["bookmark", "title", "res", "unread", "heat", "createdDate"])
      threadList.addItem(items)

      expect(table.querySelector("tbody").innerHTML).toBe(
        """
        <tr class="open_in_rcrx updated" data-href="#{dummyURL0}" data-title="dummy0" data-thread_number="0">
          <td></td><td>dummy0</td><td>123</td><td>73</td><td>#{UI.ThreadList._calcHeat(now, items[0].created_at, items[0].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL1}" data-title="dummy1" data-thread_number="1">
          <td></td><td>dummy1</td><td></td><td></td><td>#{UI.ThreadList._calcHeat(now, items[1].created_at, items[1].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL2}" data-title="dummy2" data-thread_number="2">
          <td></td><td>dummy2</td><td>12</td><td></td><td>#{UI.ThreadList._calcHeat(now, items[2].created_at, items[2].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        """.replace(/(?:\u0020{2}|\n)/g, "")
      )
      return

    it "スレのデータからDOMを構築する（/view/bookmark.html相当）", ->
      dummyURL0 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
      dummyURL1 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567891/"
      dummyURL2 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567892/"

      items = [
        {
          title: "dummy0"
          url: dummyURL0
          res_count: 123
          created_at: 1234567890 * 1000
          read_state: {
            url: dummyURL0
            read: 50
            received: 50
            last: 50
          }
        }
        {
          title: "dummy1"
          url: dummyURL1
          res_count: 0
          created_at: 1234567891 * 1000
          read_state: {
            url: dummyURL1
            read: 0
            received: 0
            last: 0
          }
        }
        {
          title: "dummy2"
          url: dummyURL2
          res_count: 12
          created_at: 1234567892 * 1000
          read_state: {
            url: dummyURL2
            read: 12
            received: 12
            last: 12
          }
        }
      ]

      threadList = new UI.ThreadList(table,
        th: ["title", "res", "unread", "heat", "createdDate"])
      threadList.addItem(items)

      expect(table.querySelector("tbody").innerHTML).toBe(
        """
        <tr class="open_in_rcrx updated" data-href="#{dummyURL0}" data-title="dummy0">
          <td>dummy0</td><td>123</td><td>73</td><td>#{UI.ThreadList._calcHeat(now, items[0].created_at, items[0].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL1}" data-title="dummy1">
          <td>dummy1</td><td></td><td></td><td>#{UI.ThreadList._calcHeat(now, items[1].created_at, items[1].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL2}" data-title="dummy2">
          <td>dummy2</td><td>12</td><td></td><td>#{UI.ThreadList._calcHeat(now, items[2].created_at, items[2].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        """.replace(/(?:\u0020{2}|\n)/g, "")
      )
      return

    it "スレのデータからDOMを構築する（/view/history.html相当）", ->
      items = [
        {
          title: "dummy0"
          url: dummyURL0
          date: 1234567890 * 1000
        }
        {
          title: "dummy1"
          url: dummyURL1
          date: 1234567891 * 1000
        }
        {
          title: "dummy2"
          url: dummyURL2
          date: 1234567892 * 1000
        }
      ]

      threadList = new UI.ThreadList(table,
        th: ["title", "viewedDate"])
      threadList.addItem(items)

      expect(table.querySelector("tbody").innerHTML).toBe(
        """
        <tr class="open_in_rcrx" data-href="#{dummyURL0}" data-title="dummy0">
          <td>dummy0</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL1}" data-title="dummy1">
          <td>dummy1</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL2}" data-title="dummy2">
          <td>dummy2</td><td>2009/02/14 08:31</td>
        </tr>
        """.replace(/(?:\u0020{2}|\n)/g, "")
      )
      return

    it "スレのデータからDOMを構築する（/view/search.html相当）", ->
      items = [
        {
          title: "dummy0"
          url: dummyURL0
          res_count: 123
          created_at: 1234567890 * 1000
          board_title: "ダミー板"
          board_url: "http://__dummyserver.2ch.net/__dummyboard/"
        }
        {
          title: "dummy1"
          url: dummyURL1
          res_count: 0
          created_at: 1234567891 * 1000
          board_title: "ダミー板"
          board_url: "http://__dummyserver.2ch.net/__dummyboard/"
        }
        {
          title: "dummy2"
          url: dummyURL2
          res_count: 12
          created_at: 1234567892 * 1000
          board_title: "ダミー板"
          board_url: "http://__dummyserver.2ch.net/__dummyboard/"
        }
      ]

      threadList = new UI.ThreadList(table,
        th: ["bookmark", "title", "boardTitle", "res", "heat", "createdDate"])
      threadList.addItem(items)

      expect(table.querySelector("tbody").innerHTML).toBe(
        """
        <tr class="open_in_rcrx" data-href="#{dummyURL0}" data-title="dummy0">
          <td></td><td>dummy0</td><td>ダミー板</td><td>123</td><td>#{UI.ThreadList._calcHeat(now, items[0].created_at, items[0].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL1}" data-title="dummy1">
          <td></td><td>dummy1</td><td>ダミー板</td><td></td><td>#{UI.ThreadList._calcHeat(now, items[1].created_at, items[1].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        <tr class="open_in_rcrx" data-href="#{dummyURL2}" data-title="dummy2">
          <td></td><td>dummy2</td><td>ダミー板</td><td>12</td><td>#{UI.ThreadList._calcHeat(now, items[2].created_at, items[2].res_count)}</td><td>2009/02/14 08:31</td>
        </tr>
        """.replace(/(?:\u0020{2}|\n)/g, "")
      )
      return
    return

  describe "::empty", ->
    it "tbody内の要素を全て削除する", ->
      threadList = new UI.ThreadList(table,
        th: ["title", "res", "unread", "heat", "createdDate"])

      tbody = table.querySelector("tbody")
      tbody.appendChild(document.createElement("tr"))
      tbody.appendChild(document.createElement("tr"))
      tbody.appendChild(document.createElement("tr"))

      threadList.empty()

      expect(tbody.innerHTML).toBe("")
      return
    return

  describe "._dateToString", ->
    it "Dateオブジェクトをスレッド一覧表示用に整形する", ->
      expect(UI.ThreadList._dateToString(new Date("2012-01-01T00:00+09:00")))
        .toBe("2012/01/01 00:00")

      expect(UI.ThreadList._dateToString(new Date("2000-12-31T23:59+09:00")))
        .toBe("2000/12/31 23:59")

      expect(UI.ThreadList._dateToString(new Date("1234-12-01T12:34+09:00")))
        .toBe("1234/12/01 12:34")
      return
    return

  describe ".calcHeat", ->
    it "スレッドの勢い（平均投稿数/日）を算出する", ->
      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-02T00:00+09:00")
          Date.parse("2012-01-01T00:00+09:00")
          1
        )
      ).toBe("1.0")

      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-01T12:00+09:00")
          Date.parse("2012-01-01T00:00+09:00")
          5
        )
      ).toBe("10.0")
      return

    it "勢いの値は小数点第一位までで四捨五入", ->
      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-04T00:00+09:00")
          Date.parse("2012-01-01T00:00+09:00")
          10
        )
      ).toBe("3.3")

      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-07T00:00+09:00")
          Date.parse("2012-01-01T00:00+09:00")
          10
        )
      ).toBe("1.7")
      return

    it "スレッド作成日時と現在時刻は最低一秒差として扱う", ->
      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-01T00:00:00+09:00")
          Date.parse("2012-01-01T00:00:00+09:00")
          1
        )
      ).toBe(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-01T00:00:01+09:00")
          Date.parse("2012-01-01T00:00:00+09:00")
          1
        )
      )

      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-01T00:00:00.01+09:00")
          Date.parse("2012-01-01T00:00:00.00+09:00")
          1
        )
      ).toBe(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-01T00:00:01+09:00")
          Date.parse("2012-01-01T00:00:00+09:00")
          1
        )
      )
      return

    it "現在の時刻よりも未来に作成されたスレッドの勢いは0とする", ->
      expect(
        UI.ThreadList._calcHeat(
          Date.parse("2012-01-01T00:00:00.00+09:00")
          Date.parse("2012-01-01T00:00:00.01+09:00")
          1
        )
      ).toBe("0.0")
      return
    return
  return
