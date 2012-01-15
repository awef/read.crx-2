module "table_sort",
  setup: ->
    html = """
      <table>
        <thead><tr><th>ID</th><th>名前</th><th>数値</th></tr></thead>
        <tbody>
          <tr><td>01</td><td>aaa</td><td>123</td></tr>
          <tr><td>02</td><td>bbb</td><td>21</td></tr>
          <tr><td>03</td><td>ccc</td><td>1.234</td></tr>
          <tr><td>04</td><td>ddd</td><td>-100</td></tr>
          <tr><td>05</td><td>eee</td><td>0</td></tr>
        </tbody>
      </table>
    """
    @$table = $(html)
    @$table.appendTo("#qunit-fixture")

    @get_table_data = ->
      data = []
      @$table
        .find("tbody > tr")
          .each ->
            tmp = []
            $(@).find("td").each ->
              tmp.push(@textContent)
              return
            data.push(tmp)
            return
      data
    return

test "thがクリックされた場合、降順ソートする", 6, ->
  @$table.table_sort()
  ok(@$table.is(".table_sort"), "ソート対象テーブルには.table_sortを付与する")
  $th = @$table.find("th:first-child")
  @$table.one "table_sort_updated", =>
    QUnit.step(2, "ソート完了後、tableにtable_sort_updatedイベントが発行される")
    strictEqual($th[0].className, "table_sort_desc", "ソート対象のthには、ソート順を表すクラスが付与される")
    deepEqual(@get_table_data(), [
      ["05", "eee", "0"]
      ["04", "ddd", "-100"]
      ["03", "ccc", "1.234"]
      ["02", "bbb", "21"]
      ["01", "aaa", "123"]
    ])
    return
  QUnit.step(1)
  $th.trigger("click")
  QUnit.step(3)
  return

test "既にソートされている項目がクリックされた場合、降順/昇順を切り替える", 4, ->
  @$table.table_sort()
  $th = @$table.find("th:first-child")

  $th.trigger("click")
  $th.trigger("click")
  strictEqual($th[0].className, "table_sort_asc", "降順ソート -> 昇順ソート")
  deepEqual(@get_table_data(), [
    ["01", "aaa", "123"]
    ["02", "bbb", "21"]
    ["03", "ccc", "1.234"]
    ["04", "ddd", "-100"]
    ["05", "eee", "0"]
  ], "降順ソート -> 昇順ソート")

  $th.trigger("click")
  strictEqual($th[0].className, "table_sort_desc", "昇順ソート -> 降順ソート")
  deepEqual(@get_table_data(), [
    ["05", "eee", "0"]
    ["04", "ddd", "-100"]
    ["03", "ccc", "1.234"]
    ["02", "bbb", "21"]
    ["01", "aaa", "123"]
  ], "昇順ソート -> 降順ソート")
  return

test "thがクリックされた時、他のthからはソート関連のクラスが削除される", 4, ->
  @$table.table_sort()
  $th = @$table.find("th:first-child")
  $th.trigger("click")
  ok($th.hasClass("table_sort_desc"))
  $th_old = $th
  $th = @$table.find("th:nth-child(2)")
  $th.trigger("click")
  ok($th.hasClass("table_sort_desc"))
  ok(not $th_old.hasClass("table_sort_desc"))
  deepEqual(@get_table_data(), [
    ["05", "eee", "0"]
    ["04", "ddd", "-100"]
    ["03", "ccc", "1.234"]
    ["02", "bbb", "21"]
    ["01", "aaa", "123"]
  ])
  return

test "クラス付与作業を自前で行い、ソートを行う事も可能", 3, ->
  $th = @$table.find("th:nth-child(3)")
  @$table.table_sort()

  $th[0].className = "table_sort_desc"
  @$table.table_sort("update")
  deepEqual(@get_table_data(), [
    ["02", "bbb", "21"]
    ["01", "aaa", "123"]
    ["03", "ccc", "1.234"]
    ["05", "eee", "0"]
    ["04", "ddd", "-100"]
  ], "降順ソート指定")

  $th[0].className = "table_sort_asc"
  @$table.table_sort("update")
  deepEqual(@get_table_data(), [
    ["04", "ddd", "-100"]
    ["05", "eee", "0"]
    ["03", "ccc", "1.234"]
    ["01", "aaa", "123"]
    ["02", "bbb", "21"]
  ], "昇順ソート指定")

  $th[0].className = "table_sort_desc"
  $th.attr("data-table_sort_type", "num")
  @$table.table_sort("update")
  deepEqual(@get_table_data(), [
    ["01", "aaa", "123"]
    ["02", "bbb", "21"]
    ["03", "ccc", "1.234"]
    ["05", "eee", "0"]
    ["04", "ddd", "-100"]
  ], "降順&自然順ソート指定")

  return

test "直接ソート項目を指定する事が可能", 4, ->
  @$table.table_sort()

  @$table.table_sort("update", sort_index: 1, sort_order: "desc")
  strictEqual(@$table.find(".table_sort_desc").index(), 1)
  deepEqual(@get_table_data(), [
    ["05", "eee", "0"]
    ["04", "ddd", "-100"]
    ["03", "ccc", "1.234"]
    ["02", "bbb", "21"]
    ["01", "aaa", "123"]
  ])

  @$table.table_sort("update", sort_index: 2, sort_order: "asc", sort_type: "num")
  strictEqual(@$table.find(".table_sort_asc").index(), 2)
  deepEqual(@get_table_data(), [
    ["04", "ddd", "-100"]
    ["05", "eee", "0"]
    ["03", "ccc", "1.234"]
    ["02", "bbb", "21"]
    ["01", "aaa", "123"]
  ])

  return

test "trの属性でもソート可能", 3, ->
  @$table.table_sort()

  count = 0
  @$table.find("tr").each ->
    $(@).attr("data-number", ++count)
    return

  @$table.find("th:first-child").trigger("click")

  @$table.table_sort("update", sort_attribute: "data-number", sort_order: "desc")
  deepEqual(@get_table_data(), [
    ["05", "eee", "0"]
    ["04", "ddd", "-100"]
    ["03", "ccc", "1.234"]
    ["02", "bbb", "21"]
    ["01", "aaa", "123"]
  ], "降順ソート")

  strictEqual(@$table.find(".table_sort_asc, .table_sort_desc").length, 0)

  @$table.table_sort("update", sort_attribute: "data-number", sort_order: "asc", sort_type: "num")
  deepEqual(@get_table_data(), [
    ["01", "aaa", "123"]
    ["02", "bbb", "21"]
    ["03", "ccc", "1.234"]
    ["04", "ddd", "-100"]
    ["05", "eee", "0"]
  ], "昇順&自然順ソート")

  return
