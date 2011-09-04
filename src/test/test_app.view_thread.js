$(function(){
  module("view_thread", {
    setup: function(){
      this.$view = $("<div>");
      this.$view.data("id_index", {});
      this.$view.data("rep_index", {});

      this.example1_data = {
        name: "名無しさん",
        mail: "sage",
        other: "2010/05/14(木) 15:41:14 ID:iTGL5FKU",
        message: "test"
      };
      this.example1_dom = $("<article>")
        .attr("data-id", "ID:iTGL5FKU")
        .append(
          $("<header>")
            .append(
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
        )[0];
    }
  });

  test("レスのデータからDOMを生成し、id_index/rep_indexを更新する", 6, function(){
    var tmp_dom;

    //>>1
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});

    //>>2
    this.example1_data.message = "test<br>&gt;&gt;1";
    this.example1_dom.querySelector(".num").textContent = "2";
    this.example1_dom.querySelector(".message").innerHTML = 'test<br><a href="javascript:undefined;" class="anchor">&gt;&gt;1</a>';
    tmp_dom = app.view_thread._const_res(1, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0, 1]});
    deepEqual(this.$view.data("rep_index"), {1: [1]});
  });

  test("もし元データにscriptタグ等が入っていても、無視する", 3, function(){
    //基本的にタグは除去
    //ただし名前欄はニダーのAAが入る事が有るのでエスケープに
    var tmp_dom;

    this.example1_data.name = "<script>名無しさん</script>";
    this.example1_dom.querySelector(".name").innerHTML = "&lt;script&gt;名無しさん&lt;/script&gt;";
    this.example1_data.mail = "<script>alert();</script>sage";
    this.example1_dom.querySelector(".mail").innerHTML = "alert();sage";
    this.example1_data.other = "2010/05/14(木) 15:41:14 <script>ID:iTGL5FKU</script>";
    this.example1_dom.querySelector(".other").innerHTML = '2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU</span>';
    this.example1_data.message = "test<script>alert();</script>";
    this.example1_dom.querySelector(".message").innerHTML = "testalert();";
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("名前欄の</b><b>はspan.obに置換する", 6, function(){
    var tmp_dom;

    this.example1_data.name = "******** </b>◆ABCDEFGH1iJ2 <b>";
    this.example1_dom.querySelector(".name").innerHTML = '******** <span class="ob">◆ABCDEFGH1iJ2 </span>';
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});

    this.example1_data.name = "</b>名無しの報告 <b></b>(北海道)<b>";
    this.example1_dom.querySelector(".name").innerHTML = '<span class="ob">名無しの報告 </span><span class="ob">(北海道)</span>';
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0, 0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("名前欄のフォントタグは容認される", 3, function(){
    var tmp_dom;

    this.example1_data.name = "<font color=#FF0000>awef★</font>";
    this.example1_dom.querySelector(".name").innerHTML = "<font color=#FF0000>awef★</font>";
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("本文中のbrタグは容認される", 3, function(){
    var tmp_dom;

    this.example1_data.message = "test<br>test<br><br>test";
    this.example1_dom.querySelector(".message").innerHTML = "test<br>test<br><br>test";
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("本文中のhrタグは容認される", 3, function(){
    var tmp_dom;

    this.example1_data.message = "test<hr>test<hr><hr>test";
    this.example1_dom.querySelector(".message").innerHTML = "test<hr>test<hr><hr>test";
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("本文中のbタグは容認される", 3, function(){
    var tmp_dom;

    this.example1_data.message = "test<b>test</b><b></b>test<b>test2</b>";
    this.example1_dom.querySelector(".message").innerHTML = "test<b>test</b><b></b>test<b>test2</b>";
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("本文中の許可されていないタグは削除される", 3, function(){
    var tmp_dom;

    this.example1_data.message = 'test<div>test</div>test<a href="test">test</a>test<script>test</script>test<style>test</style>test<test></test></test/><test';
    this.example1_dom.querySelector(".message").innerHTML = "testtesttesttesttesttesttesttesttest";
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("本文中のURLはA要素に置換される", 3, function(){
    var tmp_dom;

    this.example1_data.message = 'test http://example.com/test test';
    this.example1_dom.querySelector(".message").innerHTML = 'test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a> test';
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });

  test("本文のURL中にアンカーと解釈出来る文字列が出現した場合、該当する部分はアンカーとして扱う", 3, function(){
    var tmp_dom;

    this.example1_data.message = 'test http://example.com/test&gt;1 test';
    this.example1_dom.querySelector(".message").innerHTML = 'test <a href="http://example.com/test" target="_blank" rel="noreferrer">http://example.com/test</a><a href="javascript:undefined;" class="anchor">&gt;1</a> test';
    tmp_dom = app.view_thread._const_res(0, this.example1_data, this.$view);
    strictEqual(tmp_dom.outerHTML, this.example1_dom.outerHTML);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {1: [0]});
  });
});
