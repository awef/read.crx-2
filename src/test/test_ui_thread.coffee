module "$.fn.thread",
  setup: ->
    @example1_url = "http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/0123456789/"

    @example1_1_data =
      name: "名無しさん"
      mail: "sage"
      other: "2010/05/14(木) 15:41:14 ID:iTGL5FKU"
      message: "test"

    @example1_1_dom = $("<div>").append(
      $("<article>", class: "one")
        .attr("data-id", "ID:iTGL5FKU")
        .append(
          $("<header>").append(
            $("<span>", class: "num", text: "1")
            $("<span>", class: "name", text: "名無しさん")
            $("<span>", class: "mail", text: "sage")
            $("<span>", class: "other").append(
              document.createTextNode("2010/05/14(木) 15:41:14 ")
              $("<span>", class: "id", text: "ID:iTGL5FKU(1)")
            )
          )
          $("<div>", class: "message", text: "test")
        )
    )[0]

    @example1_2_data =
      name: "774"
      mail: ""
      other: "2010/05/14(木) 15:51:14 ID:iTGL5FKU"
      message: "test<br>&gt;&gt;1"

    @example1_2_dom = $("<div>").append(
      $("<article>", class: "one")
        .attr("data-id", "ID:iTGL5FKU")
        .append(
          $("<header>").append(
            $("<span>", class: "num", text: "1")
            $("<span>", class: "name", text: "名無しさん")
            $("<span>", class: "mail", text: "sage")
            $("<span>", class: "other").append(
              document.createTextNode("2010/05/14(木) 15:41:14 ")
              $("<span>", class: "id link", text: "ID:iTGL5FKU(2)")
              $("<span>", class: "rep link", text: "返信 (1)")
            )
          )
          $("<div>", class: "message", text: "test")
        )
      $("<article>", class: "one")
        .attr("data-id", "ID:iTGL5FKU")
        .append(
          $("<header>").append(
            $("<span>", class: "num", text: "2")
            $("<span>", class: "name", text: "774")
            $("<span>", class: "mail", text: "")
            $("<span>", class: "other").append(
              document.createTextNode("2010/05/14(木) 15:51:14 ")
              $("<span>", class: "id link", text: "ID:iTGL5FKU(2)")
            )
          )
          $("<div>", class: "message", html: """test<br><a href="javascript:undefined;" class="anchor">&gt;&gt;1</a>""")
        )
    )[0]
    return

test "レスのデータからDOM及びid_index/rep_indexを構築する", 6, ->
  $container = $("<div>").thread("init", url: @example1_url)

  $container.thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})

  $container.thread("add_item", @example1_2_data)
  strictEqual($container.html(), @example1_2_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1, 2]})
  deepEqual($container.thread("rep_index"), {1: [2]})
  return

test "元データにタグが入っていても、無視する", 6, ->
  #基本的にタグは除去
  #ただし名前欄はニダーのAAが入る事が有るのでエスケープに
  @example1_1_data.name = "<script>名無しさん</script>"
  @example1_1_dom.querySelector(".name").innerHTML = "&lt;script&gt;名無しさん&lt;/script&gt;"
  @example1_1_data.mail = "<script>alert();</script>sage"
  @example1_1_dom.querySelector(".mail").innerHTML = "alert();sage"
  @example1_1_data.other = "2010/05/14(木) 15:41:14 <script>ID:iTGL5FKU</script>"
  @example1_1_data.message = "test<script>alert();</script>"
  @example1_1_dom.querySelector(".message").innerHTML = "testalert();"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})

  @example1_1_data.other = "2010/05/14(木) 15:41:14 ID:i<p>TGL</p>5FKU"
  @example1_1_dom.querySelector(".other").innerHTML = """
    2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU(1)</span>
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "IDに使用されない文字列が含まれていた場合、それ以降をIDとして認識しない", 3, ->
  @example1_1_data.other = "2010/05/14(木) 15:41:14 ID:iTG\"L5FKU"
  @example1_1_dom.querySelector("article").setAttribute("data-id", "ID:iTG")
  @example1_1_dom.querySelector(".other").innerHTML = """
    2010/05/14(木) 15:41:14 <span class="id">ID:iTG(1)</span>"L5FKU
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTG": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "名前欄の</b><b>はspan.obに置換する", 6, ->
  @example1_1_data.name = "******** </b>◆ABCDEFGH1iJ2 <b>"
  @example1_1_dom.querySelector(".name").innerHTML = """
    ******** <span class="ob">◆ABCDEFGH1iJ2 </span>
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})

  @example1_1_data.name = "</b>名無しの報告 <b></b>(北海道)<b>"
  @example1_1_dom.querySelector(".name").innerHTML = """
    <span class="ob">名無しの報告 </span><span class="ob">(北海道)</span>
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "名前欄のフォントタグは容認される", 3, ->
  @example1_1_data.name = "<font color=#FF0000>awef★</font>"
  @example1_1_dom.querySelector(".name").innerHTML = "<font color=#FF0000>awef★</font>"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中のbrタグは容認される", 3, ->
  @example1_1_data.message = "test<br>test<br><br>test<BR>test"
  @example1_1_dom.querySelector(".message").innerHTML = "test<br>test<br><br>test<BR>test"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中のhrタグは容認される", 3, ->
  @example1_1_data.message = "test<hr>test<hr><hr>test"
  @example1_1_dom.querySelector(".message").innerHTML = "test<hr>test<hr><hr>test"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中のbタグは容認される", 3, ->
  @example1_1_data.message = "test<b>test</b><b></b>test<b>test2</b>"
  @example1_1_dom.querySelector(".message").innerHTML = "test<b>test</b><b></b>test<b>test2</b>"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中の許可されていないタグは削除される", 3, ->
  @example1_1_data.message = """
    test<div>test</div>test<a href="test">test</a>test<script>test</script>test<style>test</style>test<test></test></test/><test
  """
  @example1_1_dom.querySelector(".message").innerHTML = "testtesttesttesttesttesttesttesttest"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中のURLはA要素に置換される", 3, ->
  @example1_1_data.message = "test http://example.com/test test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中のURLは空白文字以外と隣接していても認識される", 3, ->
  @example1_1_data.message = "テストhttp://example.com/testテスト"
  @example1_1_dom.querySelector(".message").innerHTML = """
    テスト<a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a>テスト
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "アンカー表記は空白文字以外と隣接していても認識する", 3, ->
  @example1_1_data.message = "test&gt;5test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test<a href="javascript:undefined;" class="anchor">&gt;5</a>test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {5: [1]})
  return

test "アンカーとURLが隣接していた場合も認識する", 3, ->
  @example1_1_data.message = "test http://example.com/test&gt;5 &gt;6http://example.com/test test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a><a href="javascript:undefined;" class="anchor">&gt;5</a> <a href="javascript:undefined;" class="anchor">&gt;6</a><a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {5: [1], 6: [1]})
  return

test "本文中のID表記はIDリンクに置換される", 3, ->
  @example1_1_data.message = "test ID:iTGL5FKU test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "ID表記は空白文字以外と隣接していても認識する", 3, ->
  @example1_1_data.message = 'テストID:iTGL5FKUテスト'
  @example1_1_dom.querySelector(".message").innerHTML = 'テスト<a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a>テスト';
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "本文中の連続したID表記も認識する", 3, ->
  @example1_1_data.message = "test ID:iTGL5FKUiD:iTGL5FKUId:iTGL5FKUid:iTGL5FKU test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">iD:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">Id:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">id:iTGL5FKU</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "IDとURLが隣接していた場合も認識する", 3, ->
  @example1_1_data.message = "test http://example.com/testID:iTGL5FKU ID:iTGL5FKUhttp://example.com/test test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "連続したアンカーも認識する", 3, ->
  @example1_1_data.message = "test &gt;&gt;2-4, 10&gt;2＞２ test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="javascript:undefined;" class="anchor">&gt;&gt;2-4, 10</a><a href="javascript:undefined;" class="anchor">&gt;2</a><a href="javascript:undefined;" class="anchor">＞２</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {2: [1], 3: [1], 4: [1], 10: [1]})
  return

test "アンカーとIDが隣接していた場合も認識する", 3, ->
  @example1_1_data.message = "test &gt;2ID:iTGL5FKU ID:iTGL5FKU&gt;3 test"
  @example1_1_dom.querySelector(".message").innerHTML = """
    test <a href="javascript:undefined;" class="anchor">&gt;2</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor">&gt;3</a> test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {2: [1], 3: [1]})
  return

test "本文中にAAが含まれていると判定した場合は、.aaを付与する", 3, ->
  @example1_1_data.message = """
    　　 ∩＿＿＿∩<br>
    　　 | ノ　　　　　 ヽ<br>
    　　/　　●　　　● |<br>
    　 |　　　　( _●_)　 ミ<br>
    　彡､　　　|∪|　　､｀＼<br>
    /　＿＿　 ヽノ　/´>　 )<br>
    (＿＿＿）　　　/　(_／<br>
    　|　　　　　　 /<br>
      　|　　／＼　＼<br>
      　|　/　　　 )　 )<br>
    　∪　　　 （　 ＼<br>
    　　　　　　 ＼＿)<br>
  """
  @example1_1_dom.querySelector(".message").innerHTML = """
    　　 ∩＿＿＿∩<br>
    　　 | ノ　　　　　 ヽ<br>
    　　/　　●　　　● |<br>
    　 |　　　　( _●_)　 ミ<br>
    　彡､　　　|∪|　　､｀＼<br>
    /　＿＿　 ヽノ　/´>　 )<br>
    (＿＿＿）　　　/　(_／<br>
    　|　　　　　　 /<br>
      　|　　／＼　＼<br>
      　|　/　　　 )　 )<br>
    　∪　　　 （　 ＼<br>
    　　　　　　 ＼＿)<br>
  """
  @example1_1_dom.querySelector("article").className = "aa one"
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "2chのスレッドではレス冒頭のsssp://リンクを埋め込み表示する", 3, ->
  @example1_url = "http://__dummy.2ch.net/__dummy/"
  @example1_1_data.message = """
    sssp://img.2ch.net/ico/u_utyuu.gif<br>
    test
  """
  @example1_1_dom.querySelector(".message").innerHTML = """
    <img class="beicon" src="/img/loading.svg" data-src="http://img.2ch.net/ico/u_utyuu.gif" /><br />
    test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return

test "2ch以外のスレッドではsssp://リンクを無視する", 3, ->
  @example1_1_data.message = """
    sssp://img.2ch.net/ico/u_utyuu.gif<br>
    test
  """
  @example1_1_dom.querySelector(".message").innerHTML = """
    sssp://img.2ch.net/ico/u_utyuu.gif<br>
    test
  """
  $container = $("<div>").thread("init", url: @example1_url).thread("add_item", @example1_1_data)
  strictEqual($container.html(), @example1_1_dom.innerHTML)
  deepEqual($container.thread("id_index"), {"ID:iTGL5FKU": [1]})
  deepEqual($container.thread("rep_index"), {})
  return
