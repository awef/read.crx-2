describe "UI.TableSorter", ->
  $table = null
  tableSorter = null

  getTableData = ->
    data = []
    $table.find("tbody > tr").each ->
      tmp = []
      $(@).find("td").each ->
        tmp.push(@textContent)
        return
      data.push(tmp)
      return
    data

  beforeEach ->
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
    $table = $(html)
    $table.appendTo("#jasmine-fixture")
    tableSorter = new UI.TableSorter($table[0])
    return

  describe "new時", ->
    it "テーブルに.table_sortを付与する", ->
      expect($table.is(".table_sort")).toBeTruthy()
      return
    return

  describe "thがクリックされた時", ->
    $th = null

    beforeEach ->
      $th = $table.find("th:first-child")
      return

    it "他のthからはソート関連のクラスを削除する", ->
      $th2 = $table.find("th:nth-child(2)")

      $th.trigger("click")
      $th2.trigger("click")

      expect($th.hasClass("table_sort_desc")).toBeFalsy()
      expect($th2.hasClass("table_sort_desc")).toBeTruthy()
      return

    describe "ソートされていない項目の場合", ->
      it "降順ソートする", ->
        $th.trigger("click")

        expect($th[0].className).toBe("table_sort_desc")

        expect(getTableData()).toEqual([
          ["05", "eee", "0"]
          ["04", "ddd", "-100"]
          ["03", "ccc", "1.234"]
          ["02", "bbb", "21"]
          ["01", "aaa", "123"]
        ])
        return
      return

    describe "降順ソートされている項目の場合", ->
      it "昇順ソートする", ->
        $th.trigger("click").trigger("click")

        expect($th[0].className).toBe("table_sort_asc")

        expect(getTableData()).toEqual([
          ["01", "aaa", "123"]
          ["02", "bbb", "21"]
          ["03", "ccc", "1.234"]
          ["04", "ddd", "-100"]
          ["05", "eee", "0"]
        ])
        return
      return

    describe "昇順ソートされている項目の場合", ->
      it "降順ソートする", ->
        $th.trigger("click").trigger("click").trigger("click")

        expect($th[0].className).toBe("table_sort_desc")

        expect(getTableData()).toEqual([
          ["05", "eee", "0"]
          ["04", "ddd", "-100"]
          ["03", "ccc", "1.234"]
          ["02", "bbb", "21"]
          ["01", "aaa", "123"]
        ])
        return
      return
    return


  describe "::update", ->
    it "ソート前にtable_sort_before_updateイベントを送出する", ->
      cachedTableData = getTableData()

      onTableSortBeforeUpdate = jasmine.createSpy("onTableSortBeforeUpdate")
      onTableSortBeforeUpdate.andCallFake ->
        expect(getTableData()).toEqual(cachedTableData)
        return

      $table.on("table_sort_before_update", onTableSortBeforeUpdate)

      $table.find("th:first-child").trigger("click")
      expect(onTableSortBeforeUpdate.callCount).toBe(1)

      expect(getTableData()).not.toEqual(cachedTableData)
      cachedTableData = getTableData()

      $table.find("th:nth-child(2)").trigger("click")
      expect(onTableSortBeforeUpdate.callCount).toBe(2)
      return

    describe "table_sort_before_updateがpreventDefaultされた時", ->
      it "ソートをキャンセルする", ->
        cachedTableData = getTableData()

        onTableSortBeforeUpdate = jasmine.createSpy("onTableSortBeforeUpdate")
        onTableSortBeforeUpdate.andCallFake (e) ->
          e.preventDefault()
          return

        $table.on("table_sort_before_update", onTableSortBeforeUpdate)

        $table.find("th:first-child").trigger("click")
        expect(onTableSortBeforeUpdate.callCount).toBe(1)
        expect(getTableData()).toEqual(cachedTableData)

        $table.find("th:nth-child(2)").trigger("click")
        expect(onTableSortBeforeUpdate.callCount).toBe(2)
        expect(getTableData()).toEqual(cachedTableData)
        return
      return

    it "ソート完了後、table_sort_updatedイベントを送出する", ->
      onTableSortUpdated = jasmine.createSpy("onTableSortUpdated")
      $table.one("table_sort_updated", onTableSortUpdated)

      $table.find("th:first-child").trigger("click")

      waitsFor ->
        onTableSortUpdated.wasCalled

      runs ->
        expect(onTableSortUpdated.mostRecentCall.args[1]).toEqual({
          sort_index: 0
          sort_order: "desc"
          sort_type: "str"
        })
      return

    it "thのクラスに従ってソートする", ->
      $th = $table.find("th:nth-child(3)")

      $th.addClass("table_sort_desc")
      tableSorter.update()
      expect(getTableData()).toEqual([
        ["02", "bbb", "21"]
        ["01", "aaa", "123"]
        ["03", "ccc", "1.234"]
        ["05", "eee", "0"]
        ["04", "ddd", "-100"]
      ])
      $th.removeClass("table_sort_desc")

      $th.addClass("table_sort_asc")
      tableSorter.update()
      expect(getTableData()).toEqual([
        ["04", "ddd", "-100"]
        ["05", "eee", "0"]
        ["03", "ccc", "1.234"]
        ["01", "aaa", "123"]
        ["02", "bbb", "21"]
      ])
      $th.removeClass("table_sort_asc")

      $th.addClass("table_sort_desc")
      $th.attr("data-table_sort_type", "num")
      tableSorter.update()
      expect(getTableData()).toEqual([
        ["01", "aaa", "123"]
        ["02", "bbb", "21"]
        ["03", "ccc", "1.234"]
        ["05", "eee", "0"]
        ["04", "ddd", "-100"]
      ])
      return

    it "引数でソート項目を指定された場合はそれに従う", ->
      tableSorter.update(sortIndex: 1, sortOrder: "desc")
      expect($table.find(".table_sort_desc").index()).toBe(1)
      expect(getTableData()).toEqual([
        ["05", "eee", "0"]
        ["04", "ddd", "-100"]
        ["03", "ccc", "1.234"]
        ["02", "bbb", "21"]
        ["01", "aaa", "123"]
      ])

      tableSorter.update(sortIndex: 2, sortOrder: "asc", sortType: "num")
      expect($table.find(".table_sort_asc").index()).toBe(2)
      expect(getTableData()).toEqual([
        ["04", "ddd", "-100"]
        ["05", "eee", "0"]
        ["03", "ccc", "1.234"]
        ["02", "bbb", "21"]
        ["01", "aaa", "123"]
      ])
      return

    it "trの属性ソートに対応", ->
      count = 0
      $table.find("tr").each ->
        $(@).attr("data-number", ++count)
        return

      $table.find("th:first-child").trigger("click")

      tableSorter.update(sortAttribute: "data-number", sortOrder: "desc")
      expect($table.find(".table_sort_asc, .table_sort_desc").length).toBe(0)
      expect(getTableData()).toEqual([
        ["05", "eee", "0"]
        ["04", "ddd", "-100"]
        ["03", "ccc", "1.234"]
        ["02", "bbb", "21"]
        ["01", "aaa", "123"]
      ])

      tableSorter.update(sortAttribute: "data-number", sortOrder: "asc", sortType: "num")
      expect(getTableData()).toEqual([
        ["01", "aaa", "123"]
        ["02", "bbb", "21"]
        ["03", "ccc", "1.234"]
        ["04", "ddd", "-100"]
        ["05", "eee", "0"]
      ])
      return
    return
  return
