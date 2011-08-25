$(function(){
  module("view_thread", {
    setup: function(){
      this.$view = $("<div>");
      this.$view.data("id_index", {});
      this.$view.data("rep_index", {});
    }
  });

  test("レスのデータからDOMを生成し、id_index/rep_indexを更新する", 6, function(){
    var expected1 = '\
<article data-id="ID:iTGL5FKU">\
<header>\
<span class="num">1</span>\
<span class="name">名無しさん</span>\
<span class="mail"></span>\
<span class="other">2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU</span></span>\
</header>\
<div class="message">test</div>\
</article>\
';
     var expected2 = '\
<article data-id="ID:iTGL5FKU">\
<header>\
<span class="num">2</span>\
<span class="name">名無しさん</span>\
<span class="mail"></span>\
<span class="other">2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU</span></span>\
</header>\
<div class="message">test<br><a href="javascript:undefined;" class="anchor">&gt;&gt;1</a></div>\
</article>\
';
    var $container1 = $("<div>");
    $container1.append(app.view_thread._const_res(0, {
      name: "名無しさん",
      mail: "",
      other: "2010/05/14(木) 15:41:14 ID:iTGL5FKU",
      message: "test"
    }, this.$view));
    strictEqual($container1.html(), expected1);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});

    var $container2 = $("<div>");
    $container2.append(app.view_thread._const_res(1, {
      name: "名無しさん",
      mail: "",
      other: "2010/05/14(木) 15:41:14 ID:iTGL5FKU",
      message: "test<br>&gt;&gt;1"
    }, this.$view));
    strictEqual($container2.html(), expected2);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0, 1]});
    deepEqual(this.$view.data("rep_index"), {1: [1]});
  });

  test("もし元データにscriptタグ等が入っていても、無視する", 3, function(){
    //基本的にタグは除去
    //ただし名前欄はニダーのAAが入る事が有るのでエスケープに
    var expected1 = '\
<article data-id="ID:iTGL5FKU">\
<header>\
<span class="num">1</span>\
<span class="name">&lt;script&gt;名無しさん&lt;/script&gt;</span>\
<span class="mail">alert();sage</span>\
<span class="other">2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU</span></span>\
</header>\
<div class="message">testalert();</div>\
</article>\
';
    var $container1 = $("<div>");
    $container1.append(app.view_thread._const_res(0, {
      name: "<script>名無しさん</script>",
      mail: "<script>alert();</script>sage",
      other: "2010/05/14(木) 15:41:14 <script>ID:iTGL5FKU</script>",
      message: "test<script>alert();</script>"
    }, this.$view));
    strictEqual($container1.html(), expected1);
    deepEqual(this.$view.data("id_index"), {"ID:iTGL5FKU": [0]});
    deepEqual(this.$view.data("rep_index"), {});
  });
});
