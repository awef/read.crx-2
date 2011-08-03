module("app.bookmark.url_to_bookmark");

test("URLからブックマークオブジェクトを作成する", 16, function(){
  var fixed_url = "http://__dummy.2ch.net/dummy/";
  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url),
    {
      type: "board",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "板URL"
  );

  fixed_url = "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/";
  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#res_count=123"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: 123,
      read_state: null,
      expired: false
    },
    "スレURL + res_count"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#res_count"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + 不正なres_count(Boolean)"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#res_count=dummy"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + 不正なres_count(文字列)"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#expired"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: true
    },
    "スレURL + expired"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#expired=true"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false //一見trueで良さそうだけれど、URLパラメータで指定されているのはあくまで"true"という文字列
    },
    "スレURL + expired(true)"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#expired=false"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + expired(false)"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#expired=123"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + 不正なexpired(数値文字列)"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#last=123&read=234&received=345"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: {
        url: fixed_url,
        last: 123,
        read: 234,
        received: 345
      },
      expired: false
    },
    "スレURL + read_state"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#last=test&read=234&received=345"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + 不正なread_state"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#read=234&received=345"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + 不完全なread_state"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#last=123&read=234&received=345&res_count=456"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: 456,
      read_state: {
        url: fixed_url,
        last: 123,
        read: 234,
        received: 345
      },
      expired: false
    },
    "スレURL + read_state + res_count"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "#last=123&read=234&received=345&res_count=456&expired"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: 456,
      read_state: {
        url: fixed_url,
        last: 123,
        read: 234,
        received: 345
      },
      expired: true
    },
    "スレURL + read_state + res_count + expired"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "123/?test=123#123"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: null,
      read_state: null,
      expired: false
    },
    "スレURL + 無関係なオプション"
  );

  deepEqual(
    app.bookmark.url_to_bookmark(fixed_url + "123/?test=123#last=123&read=234&received=345&res_count=456&expired"),
    {
      type: "thread",
      bbs_type: "2ch",
      url: fixed_url,
      title: fixed_url,
      res_count: 456,
      read_state: {
        url: fixed_url,
        last: 123,
        read: 234,
        received: 345
      },
      expired: true
    },
    "スレURL + read_state + res_count + expired + 無関係なオプション"
  );
});

module("app.bookmark.bookmark_to_url");

test("ブックマークオブジェクトをURLに変換する", 10, function(){
  var fixed_url = "http://__dummy.2ch.net/dummy/";
  var base_bookmark = {
    type: "board",
    bbs_type: "2ch",
    url: fixed_url,
    title: fixed_url,
    res_count: null,
    read_state: null,
    expired: false
  };
  var bookmark;
  var result;

  bookmark = app.deep_copy(base_bookmark);
  strictEqual(
    app.bookmark.bookmark_to_url(bookmark),
    fixed_url,
    "板ブックマーク"
  );

  fixed_url = "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/";
  base_bookmark = {
    type: "thread",
    bbs_type: "2ch",
    url: fixed_url,
    title: fixed_url,
    res_count: null,
    read_state: null,
    expired: false
  };

  bookmark = app.deep_copy(base_bookmark);
  strictEqual(
    app.bookmark.bookmark_to_url(bookmark),
    fixed_url,
    "スレブックマーク"
  );

  bookmark = app.deep_copy(base_bookmark);
  bookmark.res_count = 123;
  strictEqual(
    app.bookmark.bookmark_to_url(bookmark),
    fixed_url + "#res_count=123",
    "スレブックマーク(res_count)"
  );

  bookmark = app.deep_copy(base_bookmark);
  bookmark.expired = true;
  strictEqual(
    app.bookmark.bookmark_to_url(bookmark),
    fixed_url + "#expired",
    "スレブックマーク(expired)"
  );

  bookmark = app.deep_copy(base_bookmark);
  bookmark.read_state = {
    url: fixed_url,
    last: 123,
    read: 234,
    received: 345
  };
  result = app.bookmark.bookmark_to_url(bookmark);
  deepEqual(
    app.url.parse_hashquery(result), {
      last: "123", read: "234", received: "345"
    }, "スレブックマーク(read_state)");
  strictEqual(app.url.fix(result), fixed_url, "スレブックマーク(read_state)");

  bookmark = app.deep_copy(base_bookmark);
  bookmark.read_state = {
    url: fixed_url,
    last: 123,
    read: 234,
    received: 345
  };
  bookmark.expired = true;
  result = app.bookmark.bookmark_to_url(bookmark);
  deepEqual(
    app.url.parse_hashquery(result), {
      last: "123", read: "234", received: "345", expired: true
    }, "スレブックマーク(read_state)");
  strictEqual(app.url.fix(result), fixed_url, "スレブックマーク(res_count + read_state)");

  bookmark = app.deep_copy(base_bookmark);
  bookmark.read_state = {
    url: fixed_url,
    last: 123,
    read: 234,
    received: 345
  };
  bookmark.expired = true;
  bookmark.res_count = 456;
  result = app.bookmark.bookmark_to_url(bookmark);
  deepEqual(
    app.url.parse_hashquery(result), {
      last: "123", read: "234", received: "345", expired: true, res_count: "456"
    }, "スレブックマーク(read_state)");
  strictEqual(app.url.fix(result), fixed_url, "スレブックマーク(res_count + read_state + res_count)");
});

module("app.bookmark", {
  setup: function(){
    this.one = function(type, listener){
      var wrapper = function(){
        listener.apply(this, arguments);
        app.message.remove_listener(type, wrapper);
      };
      app.message.add_listener(type, wrapper);
    };
  }
});

test("ブックマークされていないURLを取得しようとした時は、nullを返す", 1, function(){
  strictEqual(app.bookmark.get("http://__dummy.2ch.net/dummy/"), null);
});

asyncTest("板のブックマークを保存/取得/削除出来る", 6, function(){
  var that = this;
  var url = "http://__dummy.2ch.net/dummy/";
  var title = "ダミー板";
  var expect_bookmark = {
    type: "board",
    bbs_type: "2ch",
    title: title,
    url: url,
    res_count: null,
    read_state: null,
    expired: false
  };
  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300)
      });
    })
    .pipe(function(){
      //追加
      var deferred_on_added = $.Deferred();
      that.one("bookmark_updated", function(message){
        deepEqual(message, {type: "added", bookmark: expect_bookmark});
        deferred_on_added.resolve();
      });
      return $.when(app.bookmark.add(url, title), deferred_on_added);
    })
    .pipe(function(){
      var deferred = $.Deferred();
      //取得確認
      deepEqual(app.bookmark.get(url), expect_bookmark);
      chrome.bookmarks.getChildren(app.config.get("bookmark_id"), function(array_of_tree){
        if(array_of_tree.some(function(tree){ return tree.url === url; })){
          ok(true);
          deferred.resolve();
        }
        else{
          ok(false);
          deferred.reject();
        }
      });
      return deferred;
    })
    .pipe(function(){
      //削除
      var deferred_on_removed = $.Deferred();
      that.one("bookmark_updated", function(message){
        deepEqual(message, {type: "removed", bookmark: expect_bookmark});
        deferred_on_removed.resolve();
      });
      return $.when(app.bookmark.remove(url), deferred_on_removed);
    })
    .pipe(function(){
      var deferred = $.Deferred();
      //削除確認
      strictEqual(app.bookmark.get(url), null);
      chrome.bookmarks.getChildren(app.config.get("bookmark_id"), function(array_of_tree){
        if(array_of_tree.some(function(tree){ return tree.url === url; })){
          ok(false);
          deferred.resolve();
        }
        else{
          ok(true);
          deferred.reject();
        }
      });
      return deferred;
    })
    .always(function(){
      start();
    });
});

asyncTest("スレのブックマークを保存/取得/削除出来る", 13, function(){
  var that = this;
  var url = "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/";
  var title = "ダミースレ";
  var expect_bookmark = {
    type: "thread",
    bbs_type: "2ch",
    title: title,
    url: url,
    res_count: null,
    read_state: null,
    expired: false
  };
  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300)
      });
    })
    .pipe(function(){
      //追加
      var deferred_on_added = $.Deferred();
      that.one("bookmark_updated", function(message){
        deepEqual(message, {type: "added", bookmark: expect_bookmark});
        deferred_on_added.resolve();
      });
      return $.when(app.bookmark.add(url, title), deferred_on_added);
    })
    .pipe(function(){
      var deferred = $.Deferred();
      //取得確認
      deepEqual(app.bookmark.get(url), expect_bookmark);
      deepEqual(app.bookmark.get_by_board(app.url.thread_to_board(url)), [expect_bookmark]);
      chrome.bookmarks.getChildren(app.config.get("bookmark_id"), function(array_of_tree){
        if(array_of_tree.some(function(tree){ return tree.url === url; })){
          ok(true);
          deferred.resolve();
        }
        else{
          ok(false);
          deferred.reject();
        }
      });
      return deferred;
    })
    //expired指定テスト
    .pipe(function(){
      var deferred_on_updated = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.expired = true;

          deepEqual(message, {type: "expired", bookmark: tmp_expect}, "expired指定、更新メッセージチェック");

          deferred.resolve();
        });
      });

      var deferred_on_changed = $.Deferred(function(deferred){
        var tmp_fn = function(id, info){
          chrome.bookmarks.onChanged.removeListener(tmp_fn);
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.title = url;
          tmp_expect.expired = true;

          deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "expired指定、ブックマーク更新チェック");

          deferred.resolve();
        };
        chrome.bookmarks.onChanged.addListener(tmp_fn);
      });

      app.bookmark.update_expired(url, true);
      strictEqual(app.bookmark.get(url).expired, true, "expired指定、キャッシュ更新チェック");

      return $.when(deferred_on_updated, deferred_on_changed);
    })
    //expired指定解除テスト
    .pipe(function(){
      var deferred_on_updated = $.Deferred();
      that.one("bookmark_updated", function(message){
        deepEqual(message, {type: "expired", bookmark: expect_bookmark}, "expired解除、更新メッセージチェック");
        deferred_on_updated.resolve();
      });
      
      var deferred_on_changed = $.Deferred();
      var tmp_fn = function(id, info){
        chrome.bookmarks.onChanged.removeListener(tmp_fn);
        var tmp_expect = app.deep_copy(expect_bookmark);
        tmp_expect.title = url;

        deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "expired指定、ブックマーク更新チェック");
        deferred_on_changed.resolve();
      };
      chrome.bookmarks.onChanged.addListener(tmp_fn);

      app.bookmark.update_expired(url, false);
      strictEqual(app.bookmark.get(url).expired, false, "expired解除、キャッシュ更新チェック");

      return $.when(deferred_on_updated, deferred_on_changed);
    })
    .pipe(function(){
      //削除
      var deferred_on_removed = $.Deferred();
      that.one("bookmark_updated", function(message){
        deepEqual(message, {type: "removed", bookmark: expect_bookmark});
        deferred_on_removed.resolve();
      });
      return $.when(app.bookmark.remove(url), deferred_on_removed);
    })
    .pipe(function(){
      var deferred = $.Deferred();
      //削除確認
      strictEqual(app.bookmark.get(url), null);
      chrome.bookmarks.getChildren(app.config.get("bookmark_id"), function(array_of_tree){
        if(array_of_tree.some(function(tree){ return tree.url === url; })){
          ok(false);
          deferred.resolve();
        }
        else{
          ok(true);
          deferred.reject();
        }
      });
      return deferred;
    })
    .always(function(){
      start();
    });
});

