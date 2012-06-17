module("thread_list")

test "view_bookmark", 2, ->
  thead_expected = """
    <tr>
      <th class="title">タイトル</th>
      <th class="res">レス数</th>
      <th class="unread">未読数</th>
      <th class="heat">勢い</th>
      <th class="created_date">作成日時</th>
    </tr>
  """.replace(/(?:  |\n)/g, "")

  dummyurl0 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
  dummyurl1 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567891/"
  dummyurl2 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567892/"
  items = [
    {
      title: "dummy0"
      url: dummyurl0
      res_count: 123
      created_at: 1234567890 * 1000
      read_state: {
        url: dummyurl0
        read: 50
        received: 50
        last: 50
      }
    }
    {
      title: "dummy1"
      url: dummyurl1
      res_count: 0
      created_at: 1234567891 * 1000
      read_state: {
        url: dummyurl1
        read: 0
        received: 0
        last: 0
      }
    }
    {
      title: "dummy2"
      url: dummyurl2
      res_count: 12
      created_at: 1234567892 * 1000
      read_state: {
        url: dummyurl2
        read: 12
        received: 12
        last: 12
      }
    }
  ]

  tbody_reg = ///
    <tr\sclass="open_in_rcrx\u0020updated"\sdata\-href="#{dummyurl0}"\sdata\-title="dummy0">
      <td>dummy0</td><td>123</td><td>73</td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl1}"\sdata\-title="dummy1">
      <td>dummy1</td><td></td><td></td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl2}"\sdata\-title="dummy2">
      <td>dummy2</td><td>12</td><td></td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
  ///

  $table = $("<table>").thread_list("create",
    th: ["title", "res", "unread", "heat", "created_date"])
  strictEqual($table.find("thead").html(), thead_expected, "thead")
  $table.thread_list("add_item", items)
  ok(tbody_reg.test($table.find("tbody").html()), "tbody")
  return

test "view_board", 2, ->
  thead_expected = """
    <tr>
      <th class="bookmark">★</th>
      <th class="title">タイトル</th>
      <th class="res">レス数</th>
      <th class="unread">未読数</th>
      <th class="heat">勢い</th>
      <th class="created_date">作成日時</th>
    </tr>
  """.replace(/(?:  |\n)/g, "")

  dummyurl0 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
  dummyurl1 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567891/"
  dummyurl2 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567892/"
  items = [
    {
      title: "dummy0"
      url: dummyurl0
      res_count: 123
      created_at: 1234567890 * 1000
      read_state: {
        url: dummyurl0
        read: 50
        received: 50
        last: 50
      }
      thread_number: 0
    }
    {
      title: "dummy1"
      url: dummyurl1
      res_count: 0
      created_at: 1234567891 * 1000
      read_state: {
        url: dummyurl1
        read: 0
        received: 0
        last: 0
      }
      thread_number: 1
    }
    {
      title: "dummy2"
      url: dummyurl2
      res_count: 12
      created_at: 1234567892 * 1000
      read_state: {
        url: dummyurl2
        read: 12
        received: 12
        last: 12
      }
      thread_number: 2
    }
  ]

  tbody_reg = ///
    <tr\sclass="open_in_rcrx\u0020updated"\sdata\-href="#{dummyurl0}"\sdata\-title="dummy0"\sdata\-thread_number="0">
      <td></td><td>dummy0</td><td>123</td><td>73</td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl1}"\sdata\-title="dummy1"\sdata\-thread_number="1">
      <td></td><td>dummy1</td><td></td><td></td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl2}"\sdata\-title="dummy2"\sdata\-thread_number="2">
      <td></td><td>dummy2</td><td>12</td><td></td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
  ///

  $table = $("<table>").thread_list("create",
    th: ["bookmark", "title", "res", "unread", "heat", "created_date"])
  strictEqual($table.find("thead").html(), thead_expected, "thead")
  $table.thread_list("add_item", items)
  ok(tbody_reg.test($table.find("tbody").html()), "tbody")
  return

test "view_searh", 2, ->
  thead_expected = """
    <tr>
      <th class="bookmark">★</th>
      <th class="title">タイトル</th>
      <th class="board_title">板名</th>
      <th class="res">レス数</th>
      <th class="heat">勢い</th>
      <th class="created_date">作成日時</th>
    </tr>
  """.replace(/(?:  |\n)/g, "")

  dummyurl0 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
  dummyurl1 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567891/"
  dummyurl2 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567892/"
  items = [
    {
      title: "dummy0"
      url: dummyurl0
      res_count: 123
      created_at: 1234567890 * 1000
      board_title: "ダミー板"
      board_url: "http://__dummyserver.2ch.net/__dummyboard/"
    }
    {
      title: "dummy1"
      url: dummyurl1
      res_count: 0
      created_at: 1234567891 * 1000
      board_title: "ダミー板"
      board_url: "http://__dummyserver.2ch.net/__dummyboard/"
    }
    {
      title: "dummy2"
      url: dummyurl2
      res_count: 12
      created_at: 1234567892 * 1000
      board_title: "ダミー板"
      board_url: "http://__dummyserver.2ch.net/__dummyboard/"
    }
  ]

  tbody_reg = ///
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl0}"\sdata\-title="dummy0">
      <td></td><td>dummy0</td><td>ダミー板</td><td>123</td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl1}"\sdata\-title="dummy1">
      <td></td><td>dummy1</td><td>ダミー板</td><td></td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl2}"\sdata\-title="dummy2">
      <td></td><td>dummy2</td><td>ダミー板</td><td>12</td><td>[\d\.]+</td><td>2009/02/14\s08:31</td>
    </tr>
  ///

  $table = $("<table>").thread_list("create",
    th: ["bookmark", "title", "board_title", "res", "heat", "created_date"])
  strictEqual($table.find("thead").html(), thead_expected, "thead")
  $table.thread_list("add_item", items)
  ok(tbody_reg.test($table.find("tbody").html()), "tbody")
  return

test "view_history", 2, ->
  thead_expected = """
    <tr>
      <th class="title">タイトル</th>
      <th class="viewed_date">閲覧日時</th>
    </tr>
  """.replace(/(?:  |\n)/g, "")

  dummyurl0 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567890/"
  dummyurl1 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567891/"
  dummyurl2 = "http://__dummyserver.2ch.net/test/read.cgi/__dummyboard/1234567892/"
  items = [
    {
      title: "dummy0"
      url: dummyurl0
      date: 1234567890 * 1000
    }
    {
      title: "dummy1"
      url: dummyurl1
      date: 1234567891 * 1000
    }
    {
      title: "dummy2"
      url: dummyurl2
      date: 1234567892 * 1000
    }
  ]

  tbody_reg = ///
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl0}"\sdata\-title="dummy0">
      <td>dummy0</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl1}"\sdata\-title="dummy1">
      <td>dummy1</td><td>2009/02/14\s08:31</td>
    </tr>
    <tr\sclass="open_in_rcrx"\sdata\-href="#{dummyurl2}"\sdata\-title="dummy2">
      <td>dummy2</td><td>2009/02/14\s08:31</td>
    </tr>
  ///

  $table = $("<table>").thread_list("create",
    th: ["title", "viewed_date"])
  strictEqual($table.find("thead").html(), thead_expected, "thead")
  $table.thread_list("add_item", items)
  ok(tbody_reg.test($table.find("tbody").html()), "tbody")
  return
