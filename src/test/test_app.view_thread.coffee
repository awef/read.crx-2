$ ->
  module "view_thread",
    setup: ->
      @$view = $("<div>")
      @$view.data("id_index", {})
      @$view.data("rep_index", {})

      @example1_data =
        name: "名無しさん"
        mail: "sage"
        other: "2010/05/14(木) 15:41:14 ID:iTGL5FKU"
        message: "test"

      @example1_dom = $("<article>")
        .attr("data-id", "ID:iTGL5FKU")
        .append(
          $("<header>").append(
            $("<span class=\"num\">").text("1"),
            $("<span class=\"name\">").text("名無しさん"),
            $("<span class=\"mail\">").text("sage"),
            $("<span class=\"other\">")
              .append(document.createTextNode("2010/05/14(木) 15:41:14 "))
              .append($("<span class=\"id\">").text("ID:iTGL5FKU"))
          )
        )
        .append(
          $("<div class=\"message\">").text("test")
        )[0]

      @const_res = (res_key, res, $view, id_index, rep_index) ->
        div = document.createElement("div")
        div.innerHTML = app.view_thread._const_res_html(res_key, res, $view, id_index, rep_index)
        div.firstChild

  test "レスのデータからDOMを生成し、id_index/rep_indexを更新する", 6, ->
    #>>1
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

    #>>2
    @example1_data.message = "test<br>&gt;&gt;1"
    @example1_dom.querySelector(".num").textContent = "2"
    @example1_dom.querySelector(".message").innerHTML = """
      test<br><a href="javascript:undefined;" class="anchor">&gt;&gt;1</a>
    """
    tmp_dom = @const_res(1, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0, 1]})
    deepEqual(@$view.data("rep_index"), {1: [1]})

  test "もし元データにscriptタグ等が入っていても、無視する", 3, ->
    #基本的にタグは除去
    #ただし名前欄はニダーのAAが入る事が有るのでエスケープに
    @example1_data.name = "<script>名無しさん</script>"
    @example1_dom.querySelector(".name").innerHTML = "&lt;script&gt;名無しさん&lt;/script&gt;"
    @example1_data.mail = "<script>alert();</script>sage"
    @example1_dom.querySelector(".mail").innerHTML = "alert();sage"
    @example1_data.other = "2010/05/14(木) 15:41:14 <script>ID:iTGL5FKU</script>"
    @example1_dom.querySelector(".other").innerHTML = """
      2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU</span>
    """
    @example1_data.message = "test<script>alert();</script>"
    @example1_dom.querySelector(".message").innerHTML = "testalert();"
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "名前欄の</b><b>はspan.obに置換する", 6, ->
    @example1_data.name = "******** </b>◆ABCDEFGH1iJ2 <b>"
    @example1_dom.querySelector(".name").innerHTML = """
      ******** <span class="ob">◆ABCDEFGH1iJ2 </span>
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

    @example1_data.name = "</b>名無しの報告 <b></b>(北海道)<b>"
    @example1_dom.querySelector(".name").innerHTML = """
      <span class="ob">名無しの報告 </span><span class="ob">(北海道)</span>
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0, 0]})
    deepEqual(@$view.data("rep_index"), {})

  test "名前欄のフォントタグは容認される", 3, ->
    @example1_data.name = "<font color=#FF0000>awef★</font>"
    @example1_dom.querySelector(".name").innerHTML = "<font color=#FF0000>awef★</font>"
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中のbrタグは容認される", 3, ->
    @example1_data.message = "test<br>test<br><br>test"
    @example1_dom.querySelector(".message").innerHTML = "test<br>test<br><br>test"
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中のhrタグは容認される", 3, ->
    @example1_data.message = "test<hr>test<hr><hr>test"
    @example1_dom.querySelector(".message").innerHTML = "test<hr>test<hr><hr>test"
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中のbタグは容認される", 3, ->
    @example1_data.message = "test<b>test</b><b></b>test<b>test2</b>"
    @example1_dom.querySelector(".message").innerHTML = "test<b>test</b><b></b>test<b>test2</b>"
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中の許可されていないタグは削除される", 3, ->
    @example1_data.message = """
      test<div>test</div>test<a href="test">test</a>test<script>test</script>test<style>test</style>test<test></test></test/><test
    """
    @example1_dom.querySelector(".message").innerHTML = "testtesttesttesttesttesttesttesttest"
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中のURLはA要素に置換される", 3, ->
    @example1_data.message = "test http://example.com/test test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中のURLは空白文字以外と隣接していても認識される", 3, ->
    @example1_data.message = "テストhttp://example.com/testテスト"
    @example1_dom.querySelector(".message").innerHTML = """
      テスト<a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a>テスト
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "アンカー表記は空白文字以外と隣接していても認識する", 3, ->
    @example1_data.message = "test&gt;1test"
    @example1_dom.querySelector(".message").innerHTML = """
      test<a href="javascript:undefined;" class="anchor">&gt;1</a>test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {1: [0]})

  test "アンカーとURLが隣接していた場合、分離して解釈する", 3, ->
    @example1_data.message = "test http://example.com/test&gt;1 &gt;1http://example.com/test test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a><a href="javascript:undefined;" class="anchor">&gt;1</a> <a href="javascript:undefined;" class="anchor">&gt;1</a><a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {1: [0]})

  test "本文中のID表記はIDリンクに置換される", 3, ->
    @example1_data.message = "test ID:iTGL5FKU test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "ID表記は空白文字以外と隣接していても認識する", 3, ->
    @example1_data.message = 'テストID:iTGL5FKUテスト'
    @example1_dom.querySelector(".message").innerHTML = 'テスト<a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a>テスト';
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "本文中の連続したID表記もきちんと識別出来る", 3, ->
    @example1_data.message = "test ID:iTGL5FKUiD:iTGL5FKUId:iTGL5FKUid:iTGL5FKU test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">iD:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">Id:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">id:iTGL5FKU</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "IDとURLが隣接していた場合、分離して解釈する", 3, ->
    @example1_data.message = "test http://example.com/testID:iTGL5FKU ID:iTGL5FKUhttp://example.com/test test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "連続したアンカーも認識出来る", 3, ->
    @example1_data.message = "test &gt;&gt;1-3, 10&gt;2＞１ test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="javascript:undefined;" class="anchor">&gt;&gt;1-3, 10</a><a href="javascript:undefined;" class="anchor">&gt;2</a><a href="javascript:undefined;" class="anchor">＞１</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {1: [0], 2: [0], 3: [0], 10: [0]})

  test "アンカーとIDが隣接していた場合、分離して解釈する", 3, ->
    @example1_data.message = "test &gt;1ID:iTGL5FKU ID:iTGL5FKU&gt;1 test"
    @example1_dom.querySelector(".message").innerHTML = """
      test <a href="javascript:undefined;" class="anchor">&gt;1</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor">&gt;1</a> test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {1: [0]})

  test "本文中にAAが含まれていると判定した場合は、.aaを付与する", 3, ->
    @example1_data.message = """
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
    @example1_dom.querySelector(".message").innerHTML = """
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
    @example1_dom.classList.add("aa")

    #HTMLの順序を調整
    tmp = @example1_dom.getAttribute("data-id")
    @example1_dom.removeAttribute("data-id")
    @example1_dom.setAttribute("data-id", "ID:iTGL5FKU")

    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "2chのスレッドではレス冒頭のsssp://なリンクを埋め込みする", 3, ->
    @$view.attr("data-url", "http://_dummy.2ch.net/test/read.cgi/dummy/123/")
    @example1_data.message = """
      sssp://img.2ch.net/ico/u_utyuu.gif<br>
      test
    """
    @example1_dom.querySelector(".message").innerHTML = """
      <img class="beicon" src="http://img.2ch.net/ico/u_utyuu.gif" /><br />
      test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "2ch以外のスレッドではsssp://なリンクを無視する", 3, ->
    @$view.attr("data-url", "http://jbbs.livedoor.jp/bbs/read.cgi/dummy/0/0/")
    @example1_data.message = """
      sssp://img.2ch.net/ico/u_utyuu.gif<br>
      test
    """
    @example1_dom.querySelector(".message").innerHTML = """
      sssp://img.2ch.net/ico/u_utyuu.gif<br>
      test
    """
    tmp_dom = @const_res(0, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index"))
    strictEqual(tmp_dom.outerHTML, @example1_dom.outerHTML)
    deepEqual(@$view.data("id_index"), {"ID:iTGL5FKU": [0]})
    deepEqual(@$view.data("rep_index"), {})

  test "レス番号が数値以外だった場合はnullを返す", 4, ->
    strictEqual(@const_res("0", @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index")), null)
    strictEqual(@const_res(NaN, @example1_data, @$view, @$view.data("id_index"), @$view.data("rep_index")), null)
    deepEqual(@$view.data("id_index"), {})
    deepEqual(@$view.data("rep_index"), {})
    return
