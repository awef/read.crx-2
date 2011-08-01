module("app.util.parse_anchor");

test("アンカーが含まれる文字列を解析する", 4, function(){
  deepEqual(app.util.parse_anchor("&gt;&gt;1"),
    {data: [{segments: [[1, 1]], target: 1}], target: 1});
  deepEqual(app.util.parse_anchor("&gt;&gt;100"),
    {data: [{segments: [[100, 100]], target: 1}], target: 1});
  deepEqual(app.util.parse_anchor("&gt;&gt;1000"),
    {data: [{segments: [[1000, 1000]], target: 1}], target: 1});
  deepEqual(app.util.parse_anchor("&gt;&gt;10000"),
    {data: [{segments: [[10000, 10000]], target: 1}], target: 1});
});

test("ハイフンで範囲指定が出来る", 4, function(){
  deepEqual(app.util.parse_anchor("&gt;&gt;1-3"),
    {data: [{segments: [[1, 3]], target: 3}], target: 3});
  deepEqual(app.util.parse_anchor("&gt;&gt;10-25"),
    {data: [{segments: [[10, 25]], target: 16}], target: 16});
  deepEqual(app.util.parse_anchor("&gt;&gt;1ー3"),
    {data: [{segments: [[1, 3]], target: 3}], target: 3});
  deepEqual(app.util.parse_anchor("&gt;&gt;1ー3, 4ー6"),
    {data: [{segments: [[1, 3], [4, 6]], target: 6}], target: 6});
});

test("カンマで区切って複数のアンカーを指定出来る", 3, function(){
  deepEqual(app.util.parse_anchor("&gt;&gt;1,2,3 ,"),
    {data: [{segments: [[1, 1], [2, 2], [3, 3]], target: 3}], target: 3});
  deepEqual(app.util.parse_anchor("&gt;&gt;1, 20"),
    {data: [{segments: [[1, 1], [20, 20]], target: 2}], target: 2});
  deepEqual(app.util.parse_anchor("&gt;&gt;1,    2, 3,"),
    {data: [{segments: [[1, 1], [2, 2], [3, 3]], target: 3}], target: 3});
});

test("範囲指定とカンマ区切りは混合出来る", 1, function(){
  deepEqual(app.util.parse_anchor("&gt;&gt;1,2-10,12 ,"),
    {data: [{segments: [[1, 1], [2, 10], [12, 12]], target: 11}], target: 11});
});

test("\&gt;\"の数は一つでも認識する", 1, function(){
  deepEqual(app.util.parse_anchor("&gt;1,2-10,12 ,"),
    {data: [{segments: [[1, 1], [2, 10], [12, 12]], target: 11}], target: 11});
});

test("全角の\"＞\"も開始文字として認識する", 1, function(){
  deepEqual(app.util.parse_anchor("＞1,2-10,12 ,"),
    {data: [{segments: [[1, 1], [2, 10], [12, 12]], target: 11}], target: 11});
});

module("app.util.ch_sever_move_detect");

asyncTest("htmlとして不正な文字列を渡された場合はrejectする", 1, function(){
  var html = "dummy";
  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/", html)
    .fail(function(){
      ok(true);
      start();
    });
});

asyncTest("実例テスト: pc11/linux → hibari/linux (html)", 1, function(){
  var html = '\
<html>\n\
<head>\n\
<script language="javascript">\n\
window.location.href="http://hibari.2ch.net/linux/"</script>\n\
<title>2chbbs..</title>\n\
<META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=Shift_JIS">\n\
</head>\n\
<body bgcolor="#FFFFFF">\n\
Change your bookmark ASAP.\n\
<a href="http://hibari.2ch.net/linux/">GO !</a>\n\
</body>\n\
</html>\n\
';

  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/", html)
    .done(function(new_board_url){
      strictEqual(new_board_url, "http://hibari.2ch.net/linux/");
      start();
    });
});

/*
TODO

asyncTest "pc11/linux → hibari/linux (xhr)", 1, ->
  app.util.ch_server_move_detect("http://pc11.2ch.net/linux/")
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hibari.2ch.net/linux/")
      start()

asyncTest "yuzuru/gameswf → hato/gameswf (xhr)", 1, ->
  app.util.ch_server_move_detect("http://yuzuru.2ch.net/gameswf/")
    .done (new_board_url) ->
      strictEqual(new_board_url, "http://hato.2ch.net/gameswf/")
      start()

asyncTest "example.com (xhr)", 1, ->
  app.util.ch_server_move_detect("http://example.com/")
    .fail ->
      ok(true)
      start()
*/

module("app.util.decode_char_reference", {
  setup: function(){
    this.test = function(a, b){
      strictEqual(app.util.decode_char_reference(a), b);
    };
  }
});

test("数値文字参照（十進数）をデコードできる", 5, function(){
  var test = this.test;
  test("&#0161;", "¡");
  test("&#0165;", "¥");
  test("&#0169;", "©");
  test("&#0181;", "µ");
  test("&#0255;", "ÿ");
});

test("数値文字参照（十六進数、大文字）をデコードできる", 5, function(){
  var test = this.test;
  test("&#x00A1;", "¡");
  test("&#x00A5;", "¥");
  test("&#x00A9;", "©");
  test("&#x00B5;", "µ");
  test("&#x00FF;", "ÿ");
});

test("数値文字参照（十六進数、小文字）をデコードできる", 5, function(){
  var test = this.test;
  test("&#x00a1;", "¡");
  test("&#x00a5;", "¥");
  test("&#x00a9;", "©");
  test("&#x00b5;", "µ");
  test("&#x00ff;", "ÿ");
});

test("XML実体参照をデコードできる", 5, function(){
  var test = this.test;
  test("&amp;", "&");
  test("&lt;", "<");
  test("&gt;", ">");
  test("&quot;", "\"");
  test("&apos;", "'");
});

test("実例テスト", 3, function(){
  var test = this.test;
  test("★☆★【雲雀|朱鷺】VIP&amp;VIP+運用情報387★☆★",
    "★☆★【雲雀|朱鷺】VIP&VIP+運用情報387★☆★");
  test("お、おい！&gt;&gt;5が息してねえぞ！",
    "お、おい！>>5が息してねえぞ！");
  test("【ブログ貼付】 &lt;iframe&gt;タグの不具合 ",
    "【ブログ貼付】 <iframe>タグの不具合 ");
});
