module "accordion",
  setup: ->
    html = """
      <div>
        <h2>test0</h2>
        <div>content0</div>
        <h2>test1</h2>
        <div>content1</div>
        <h2>test2</h2>
        <div>content2</div>
      </div>
    """
    @$accordion = $(html)
    @$accordion.appendTo("#qunit-fixture")
    return

test "アコーディオンには.accordionを付与する", 1, ->
  @$accordion.accordion()
  ok(@$accordion.is(".accordion"))
  return

test "セットアップ時に最初のアイテムを自動で開く", 2, ->
  @$accordion.accordion()
  ok(@$accordion.find(":header:first").is(".accordion_open"))
  strictEqual(@$accordion.find(".accordion_open").length, 1)
  return

test "項目をクリックすると、その項目を開閉する", 2, ->
  @$accordion.accordion()
  @$accordion.find(":header:first").trigger("click")
  strictEqual(@$accordion.find(".accordion_open").length, 0)
  @$accordion.find(":header:first").trigger("click")
  strictEqual(@$accordion.find(".accordion_open").length, 1)
  return

test "閉じている項目をクリックした時、既に開いている項目が有った場合、それを閉じる", 2, ->
  @$accordion.accordion()
  @$accordion.find(":header:eq(2)").trigger("click")
  ok(@$accordion.find(":header:eq(2)").is(".accordion_open"))
  strictEqual(@$accordion.find(".accordion_open").length, 1)
  return

test "同じ要素に二回目以降の$.fn.accordion()が呼ばれた時も、初めて$.fn.accordion()した場合と同様の結果になる", 3, ->
  @$accordion.accordion()
  @$accordion.find(":header:eq(2)").trigger("click")
  @$accordion.accordion()
  ok(@$accordion.is(".accordion"))
  ok(@$accordion.find(":header:first").is(".accordion_open"))
  strictEqual(@$accordion.find(".accordion_open").length, 1)
  return
