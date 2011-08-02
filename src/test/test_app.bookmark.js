module("app.bookmark");

test("ブックマークされていないURLを取得しようとした時は、nullを返す", 1, function(){
  strictEqual(app.bookmark.get("http://__dummy.2ch.net/dummy/"), null);
});

asyncTest("板のブックマークを保存/取得/削除出来る", 6, function(){
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

  var deferred_on_added = $.Deferred();
  var on_added = function(message){
    deepEqual(message, {type: "added", bookmark: expect_bookmark});
    deferred_on_added.resolve();
    app.message.remove_listener("bookmark_updated", on_added);
  };

  var deferred_on_removed = $.Deferred();
  var on_removed = function(message){
    deepEqual(message, {type: "removed", bookmark: expect_bookmark});
    deferred_on_removed.resolve();
    app.message.remove_listener("bookmark_updated", on_removed);
  };

  //追加
  app.message.add_listener("bookmark_updated", on_added);
  $.when(app.bookmark.add(url, title), deferred_on_added)
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
      app.message.add_listener("bookmark_updated", on_removed);
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

asyncTest("スレのブックマークを保存/取得/削除出来る", 7, function(){
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

  var deferred_on_added = $.Deferred();
  var on_added = function(message){
    deepEqual(message, {type: "added", bookmark: expect_bookmark});
    deferred_on_added.resolve();
    app.message.remove_listener("bookmark_updated", on_added);
  };

  var deferred_on_removed = $.Deferred();
  var on_removed = function(message){
    deepEqual(message, {type: "removed", bookmark: expect_bookmark});
    deferred_on_removed.resolve();
    app.message.remove_listener("bookmark_updated", on_removed);
  };

  //追加
  app.message.add_listener("bookmark_updated", on_added);
  $.when(app.bookmark.add(url, title), deferred_on_added)
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
    .pipe(function(){
      //削除
      app.message.add_listener("bookmark_updated", on_removed);
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

