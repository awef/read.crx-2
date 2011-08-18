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
        }, 300);
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

asyncTest("スレのブックマークを保存/取得/削除出来る", 32, function(){
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
  var node_id;

  var get_deferred_on_message = function(type, label){
    return $.Deferred(function(deferred){
      that.one("bookmark_updated", function(message){
        deepEqual(message, {type: type, bookmark: expect_bookmark}, label);
        deferred.resolve();
      });
    });
  };

  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300);
      });
    })
    //ブックマーク追加テスト
    .pipe(function(){
      var deferred_on_added = get_deferred_on_message("added", "ブックマーク追加 - 更新メッセージチェック");

      var deferred_on_created = $.Deferred(function(deferred){
        var tmp_fn = function(id, tree){
          chrome.bookmarks.onCreated.removeListener(tmp_fn);
          strictEqual(tree.url, url, "ブックマーク追加 - ブックマーク更新チェック");
          node_id = id;
          deferred.resolve();
        };
        chrome.bookmarks.onCreated.addListener(tmp_fn);
      });

      var deferred_add = app.bookmark.add(url, title);

      return $.when(deferred_add, deferred_on_added, deferred_on_created);
    })
    .pipe(function(){
      deepEqual(app.bookmark.get(url), expect_bookmark, "ブックマーク追加 - キャッシュ更新チェック");
      deepEqual(app.bookmark.get_by_board(app.url.thread_to_board(url)), [expect_bookmark], "ブックマーク追加 - キャッシュ更新チェック(2)");
    })
    //重複追加テスト
    .pipe(function(){
      return $.Deferred(function(deferred){
        app.bookmark.add(url, title)
          .fail(function(){
            ok(true, "既に存在するブックマークを追加しようとしても失敗する");
            deferred.resolve();
          });
      });
    })
    //重複ブックマーク作成時テスト
    .pipe(function(){
      return $.Deferred(function(deferred){
        chrome.bookmarks.create({
            parentId: app.config.get("bookmark_id"),
            url: url,
            title: "重複テスト"
          }, function(node){ deferred.resolve(node); });
      });
    })
    .pipe(function(node){
      return $.Deferred(function(deferred){
        setTimeout(function(){ deferred.resolve(node); }, 300);
      });
    })
    .pipe(function(node){
      return $.Deferred(function(deferred){
        deepEqual(app.bookmark.get(url), expect_bookmark, "重複したブックマークが検出されても既存のブックマークには影響が無い");
        deepEqual(app.bookmark.get_by_board(app.url.thread_to_board(url))
          , [expect_bookmark], "重複したブックマークが検出されても既存のブックマークには影響が無い(2)");
        chrome.bookmarks.remove(node.id, function(){
          deferred.resolve();
        });
      });
    })
    //res_count付与テスト
    .pipe(function(){
      var deferred_on_message = get_deferred_on_message("res_count", "res_count付与 - 更新メッセージチェック");

      var deferred_on_change = $.Deferred(function(deferred){
        var tmp_fn = function(id, info){
          chrome.bookmarks.onChanged.removeListener(tmp_fn);
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.title = url;
          deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "rescount付与 - ブックマーク更新チェック");
          deferred.resolve();
        };
        chrome.bookmarks.onChanged.addListener(tmp_fn);
      });

      expect_bookmark.res_count = 123;
      app.bookmark.update_res_count(url, 123);
      deepEqual(app.bookmark.get(url), expect_bookmark, "res_count付与テスト - キャッシュ更新チェック");

      return $.when(deferred_on_message, deferred_on_change);
    })
    //res_count更新テスト
    .pipe(function(){
      var deferred_on_message = get_deferred_on_message("res_count", "res_count更新 - 更新メッセージチェック");

      var deferred_on_change = $.Deferred(function(deferred){
        var tmp_fn = function(id, info){
          chrome.bookmarks.onChanged.removeListener(tmp_fn);
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.title = url;
          deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "rescount更新 - ブックマーク更新チェック");
          deferred.resolve();
        };
        chrome.bookmarks.onChanged.addListener(tmp_fn);
      });

      expect_bookmark.res_count = 234;
      app.bookmark.update_res_count(url, 234);
      deepEqual(app.bookmark.get(url), expect_bookmark, "res_count付与テスト - キャッシュ更新チェック");

      return $.when(deferred_on_message, deferred_on_change);
    })
    //expired指定テスト
    .pipe(function(){
      var deferred_on_updated = get_deferred_on_message("expired", "expired指定、更新メッセージチェック");

      var deferred_on_changed = $.Deferred(function(deferred){
        var tmp_fn = function(id, info){
          chrome.bookmarks.onChanged.removeListener(tmp_fn);
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.title = url;

          deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "expired指定、ブックマーク更新チェック");

          deferred.resolve();
        };
        chrome.bookmarks.onChanged.addListener(tmp_fn);
      });

      expect_bookmark.expired = true;
      app.bookmark.update_expired(url, true);
      strictEqual(app.bookmark.get(url).expired, true, "expired指定、キャッシュ更新チェック");

      return $.when(deferred_on_updated, deferred_on_changed);
    })
    //expired指定解除テスト
    .pipe(function(){
      var deferred_on_updated = get_deferred_on_message("expired", "expired解除、更新メッセージチェック");

      var deferred_on_changed = $.Deferred();
      var tmp_fn = function(id, info){
        chrome.bookmarks.onChanged.removeListener(tmp_fn);
        var tmp_expect = app.deep_copy(expect_bookmark);
        tmp_expect.title = url;

        deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "expired指定、ブックマーク更新チェック");
        deferred_on_changed.resolve();
      };
      chrome.bookmarks.onChanged.addListener(tmp_fn);

      expect_bookmark.expired = false;
      app.bookmark.update_expired(url, false);
      strictEqual(app.bookmark.get(url).expired, false, "expired解除、キャッシュ更新チェック");

      return $.when(deferred_on_updated, deferred_on_changed);
    })
    //read_state付与テスト
    .pipe(function(){
      var read_state = {
        url: url,
        read: 50,
        last: 25,
        received: 100
      };

      var deferred_on_change = $.Deferred(function(deferred){
        var tmp_fn = function(id, info){
          chrome.bookmarks.onChanged.removeListener(tmp_fn);
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.title = url;
          deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "read_state付与 - ブックマーク更新チェック");
          deferred.resolve();
        };
        chrome.bookmarks.onChanged.addListener(tmp_fn);
      });

      var deferred_on_message = $.Deferred(function(deferred){
        that.one("read_state_updated", function(message){
          deepEqual(message, {
            board_url: app.url.thread_to_board(read_state.url),
            read_state: read_state
          }, "read_state付与 - read_state_updatedメッセージチェック");
          deferred.resolve();
        });
      });

      expect_bookmark.read_state = read_state;
      app.bookmark.update_read_state(read_state);
      deepEqual(app.bookmark.get(url), expect_bookmark, "read_state付与テスト - キャッシュ更新チェック");

      return $.when(deferred_on_change, deferred_on_message);
    })
    //read_state更新テスト
    .pipe(function(){
      var read_state = {
        url: url,
        read: 119,
        last: 118,
        received: 120
      };

      var deferred_on_change = $.Deferred(function(deferred){
        var tmp_fn = function(id, info){
          chrome.bookmarks.onChanged.removeListener(tmp_fn);
          var tmp_expect = app.deep_copy(expect_bookmark);
          tmp_expect.title = url;
          deepEqual(app.bookmark.url_to_bookmark(info.url), tmp_expect, "read_state更新 - ブックマーク更新チェック");
          deferred.resolve();
        };
        chrome.bookmarks.onChanged.addListener(tmp_fn);
      });

      var deferred_on_message = $.Deferred(function(deferred){
        that.one("read_state_updated", function(message){
          deepEqual(message, {
            board_url: app.url.thread_to_board(read_state.url),
            read_state: read_state
          }, "read_state更新 - read_state_updatedメッセージチェック");
          deferred.resolve();
        });
      });

      expect_bookmark.read_state = read_state;
      app.bookmark.update_read_state(read_state);
      deepEqual(app.bookmark.get(url), expect_bookmark, "read_state更新テスト - キャッシュ更新チェック");

      return $.when(deferred_on_change, deferred_on_message);
    })
    //ブックマーク編集(res_count変更)テスト
    .pipe(function(){
      var deferred_on_message = get_deferred_on_message("res_count", "ブックマーク編集(res_count変更)テスト");

      expect_bookmark.res_count = 123;
      chrome.bookmarks.update(node_id, {
        url: app.bookmark.bookmark_to_url(expect_bookmark)
      });

      return deferred_on_message;
    })
    //ブックマーク編集(expired指定)テスト
    .pipe(function(){
      var deferred_on_message = get_deferred_on_message("expired", "ブックマーク編集(expired指定)テスト");

      expect_bookmark.expired = true;
      chrome.bookmarks.update(node_id, {
        url: app.bookmark.bookmark_to_url(expect_bookmark)
      });

      return deferred_on_message;
    })
    //ブックマーク編集(expired解除)テスト
    .pipe(function(){
      var deferred_on_message = get_deferred_on_message("expired", "ブックマーク編集(expired解除)テスト");

      expect_bookmark.expired = false;
      chrome.bookmarks.update(node_id, {
        url: app.bookmark.bookmark_to_url(expect_bookmark)
      });

      return deferred_on_message;
    })
    //削除
    .pipe(function(){
      var deferred_on_removed = get_deferred_on_message("removed", "削除メッセージ");
      return $.when(app.bookmark.remove(url), deferred_on_removed);
    })
    //削除確認
    .pipe(function(){
      var deferred = $.Deferred(function(deferred){
        strictEqual(app.bookmark.get(url), null);
        chrome.bookmarks.getChildren(app.config.get("bookmark_id"), function(array_of_tree){
          if(array_of_tree.some(function(tree){ return tree.url === url; })){
            ok(false, "削除確認");
            deferred.reject();
          }
          else{
            ok(true, "削除確認");
            deferred.resolve();
          }
        });
      });
      return deferred;
    })
    //存在しないURLの削除テスト
    .pipe(function(){
      return $.Deferred(function(deferred){
        app.bookmark.remove(url)
          .done(function(){
            ok(false, "存在しないURLの削除テスト");
            deferred.resolve();
          })
          .fail(function(){
            ok(true, "存在しないURLの削除テスト");
            deferred.resolve();
          });
      });
    })
    .always(function(){
      start();
    });
});

asyncTest("パラメータ付きのスレURLも認識出来る", 2, function(){
  var that = this;
  var url = "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/";
  url += "#res_count=123&last=10&read=20&received=100";
  var title = "ダミースレ";
  var expect_bookmark = {
    type: "thread",
    bbs_type: "2ch",
    title: title,
    url: app.url.fix(url),
    res_count: 123,
    read_state: {
      url: app.url.fix(url),
      last: 10,
      read: 20,
      received: 100
    },
    expired: false
  };
  var node_id;

  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300);
      });
    })
    .pipe(function(){
      var deferred_added_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "added", bookmark: expect_bookmark});
          deferred.resolve();
        });
      });

      var deferred_create = $.Deferred(function(deferred){
        chrome.bookmarks.create({
            parentId: app.config.get("bookmark_id"),
            url: url,
            title: title
          }, function(node){
            node_id = node.id;
            deferred.resolve();
        });
      });

      return $.when(deferred_create, deferred_added_message);
    })
    .pipe(function(){
     var deferred_removed_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "removed", bookmark: expect_bookmark});
          deferred.resolve();
        });
      });

      var deferred_remove = $.Deferred(function(deferred){
        chrome.bookmarks.remove(node_id, function(){
          deferred.resolve()
        });
      });

      return $.when(deferred_remove, deferred_removed_message);
    })
    .always(function(){
      start();
    });
});

asyncTest("ノードのURL変更にも追随する", 4, function(){
  var that = this;
  var url = "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/";
  url += "#res_count=123&last=10&read=20&received=100";
  var title = "ダミースレ";
  var expect_bookmark = {
    type: "thread",
    bbs_type: "2ch",
    title: title,
    url: app.url.fix(url),
    res_count: 123,
    read_state: {
      url: app.url.fix(url),
      last: 10,
      read: 20,
      received: 100
    },
    expired: false
  };
  var node_id;

  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300);
      });
    })
    .pipe(function(){
      var deferred_added_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "added", bookmark: expect_bookmark});
          deferred.resolve();
        });
      });

      var deferred_create = $.Deferred(function(deferred){
        chrome.bookmarks.create({
            parentId: app.config.get("bookmark_id"),
            url: url,
            title: title
          }, function(node){
            node_id = node.id;
            deferred.resolve();
        });
      });

      return $.when(deferred_create, deferred_added_message);
    })
    //他鯖・他板・他スレへの変更
    .pipe(function(){
      var old_expect = app.deep_copy(expect_bookmark);
      url = "http://__dummy_server2.2ch.net/test/read.cgi/__dummy_board2/0987654321/";
      url += "#res_count=123&last=10&read=20&received=100";
      title = "ダミースレ2";
      expect_bookmark.url = expect_bookmark.read_state.url = app.url.fix(url);
      expect_bookmark.title = title;

      var deferred_on_removed = $.Deferred(function(deferred){
        var tmp = function(message){
          if (message.type === "removed") {
            deepEqual(message, {type: "removed", bookmark: old_expect});
            app.message.remove_listener("bookmark_updated", tmp);
            deferred.resolve();
          }
        };
        app.message.add_listener("bookmark_updated", tmp);
      });

      var deferred_on_added = $.Deferred(function(deferred){
        var tmp = function(message){
          if (message.type === "added") {
            deepEqual(message, {type: "added", bookmark: expect_bookmark});
            app.message.remove_listener("bookmark_updated", tmp);
            deferred.resolve();
          }
        };
        app.message.add_listener("bookmark_updated", tmp);
      });

      chrome.bookmarks.update(node_id, {url: url, title: title});

      return $.when(deferred_on_removed, deferred_on_added);
    })
    .pipe(function(){
     var deferred_removed_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "removed", bookmark: expect_bookmark});
          deferred.resolve();
        });
      });

      var deferred_remove = $.Deferred(function(deferred){
        chrome.bookmarks.remove(node_id, function(){
          deferred.resolve();
        });
      });

      return $.when(deferred_remove, deferred_removed_message);
    })
    .always(function(){
      start();
    });
});

asyncTest("detected_ch_server_moveメッセージを受信すると、板やスレのブックマークを移転に対応して変更する", 8, function(){
  var that = this;
  var board_title = "ダミー板（移転テスト）";
  var before_board_url = "http://__dummy_before.2ch.net/dummy/";
  var after_board_url = "http://__dummy_after.2ch.net/dummy/";
  var before_board_expect_bookmark = {
    type: "board",
    bbs_type: "2ch",
    title: board_title,
    url: before_board_url,
    res_count: null,
    read_state: null,
    expired: false
  };
  var after_board_expect_bookmark = app.deep_copy(before_board_expect_bookmark);
  after_board_expect_bookmark.url = after_board_url;

  var before_thread_url = "http://__dummy_before.2ch.net/test/read.cgi/dummy/1234567890/#res_count=123";
  var thread_title = "ダミースレ";
  var before_thread_expect_bookmark = {
    type: "thread",
    bbs_type: "2ch",
    title: thread_title,
    url: app.url.fix(before_thread_url),
    res_count: 123,
    read_state: null,
    expired: false
  };
  var after_thread_url = "http://__dummy_after.2ch.net/test/read.cgi/dummy/1234567890/";
  var after_thread_expect_bookmark = app.deep_copy(before_thread_expect_bookmark);
  after_thread_expect_bookmark.url = after_thread_url;

  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300);
      });
    })
    //板ブックマーク追加
    .pipe(function(){
      var deferred_added_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "added", bookmark: before_board_expect_bookmark});
          deferred.resolve();
        });
      });
      app.bookmark.add(before_board_url, board_title);
      return deferred_added_message;
    })
    //スレブックマーク追加
    .pipe(function(){
      var deferred_added_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "added", bookmark: before_thread_expect_bookmark});
          deferred.resolve();
        });
      });
      app.bookmark.add(before_thread_url, thread_title);
      return deferred_added_message;
    })
    //板ブックマーク移転確認
    .pipe(function(){
      var message_check = function(message){
        if (message.type === "removed") {
          if (message.bookmark.title === board_title) {
            deepEqual(message, {type: "removed", bookmark: before_board_expect_bookmark});
          }
          else {
            deepEqual(message, {type: "removed", bookmark: before_thread_expect_bookmark});
          }
        }
        else {
          if (message.bookmark.title === board_title) {
            deepEqual(message, {type: "added", bookmark: after_board_expect_bookmark});
          }
          else {
            deepEqual(message, {type: "added", bookmark: after_thread_expect_bookmark});
          }
        }
      };
      var deferred_message_check = $.Deferred(function(deferred){
        var count = 0;
        var listener = function(message){
          message_check(message);
          if (++count === 4) {
            app.message.remove_listener("bookmark_updated", listener);
            deferred.resolve();
          }
        };
        app.message.add_listener("bookmark_updated", listener);
      });
      app.message.send("detected_ch_server_move", {
        before: before_board_url,
        after: after_board_url
      });
      return deferred_message_check;
    })
    //板ブックマーク削除
    .pipe(function(){
      var deferred_removed_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "removed", bookmark: after_board_expect_bookmark});
          deferred.resolve();
        });
      });
      app.bookmark.remove(after_board_url);
      return deferred_removed_message;
    })
    //スレブックマーク削除
    .pipe(function(){
      var deferred_removed_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "removed", bookmark: after_thread_expect_bookmark});
          deferred.resolve();
        });
      });
      app.bookmark.remove(after_thread_url);
      return deferred_removed_message;
    })
    .always(function(){
      start();
    });
});

asyncTest("ノードのフォルダ内での移動は無視する", 2, function(){
  var that = this;
  var url = "http://__dummy_server.2ch.net/test/read.cgi/__dummy_board/1234567890/";
  var title = "ダミースレ";
  var expect_bookmark = {
    type: "thread",
    bbs_type: "2ch",
    title: title,
    url: app.url.fix(url),
    res_count: null,
    read_state: null,
    expired: false
  };
  var node_id;

  app.bookmark.promise_first_scan
    .pipe(function(){
      return $.Deferred(function(deferred){
        setTimeout(function(){
          deferred.resolve();
        }, 300);
      });
    })
    .pipe(function(){
      var deferred_added_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "added", bookmark: expect_bookmark});
          deferred.resolve();
        });
      });

      var deferred_create = $.Deferred(function(deferred){
        chrome.bookmarks.create({
            parentId: app.config.get("bookmark_id"),
            url: url,
            title: title
          }, function(node){
            node_id = node.id;
            deferred.resolve();
        });
      });

      return $.when(deferred_create, deferred_added_message);
    })
    .pipe(function(){
      var deferred_removed_message = $.Deferred(function(deferred){
        that.one("bookmark_updated", function(message){
          deepEqual(message, {type: "removed", bookmark: expect_bookmark});
          deferred.resolve();
        });
      });

      $.Deferred(function(deferred){
        chrome.bookmarks.move(node_id, {parentId: app.config.get("bookmark_id"), index: 0}, function(){
          deferred.resolve();
        });
      })
      .done(function(){
        chrome.bookmarks.remove(node_id);
      });

      return deferred_removed_message;
    })
    .always(function(){
      start();
    });
});
