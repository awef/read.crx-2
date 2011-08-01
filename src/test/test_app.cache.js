module("app.cache");

asyncTest("キャッシュの保存/取得/削除が出来る", 4, function(){
  original_cache = {
    url: "__test",
    data: "hogehoge",
    last_modified: (new Date("2010-01-01T00:00")).getTime(),
    last_updated: (new Date("2010-01-01T05:00")).getTime()
  };

  app.cache.set(original_cache)
    .pipe(function(){
      ok(true, "app.cache.set done");
      return app.cache.get(original_cache.url)
    }, function(){
      ok(false, "app.cache.set fail");
    })

    .pipe(function(res){
      deepEqual(res.data, original_cache, "キャッシュ内容チェック");
      return app.cache.remove(original_cache.url);
    }, function(){
      ok(false, "app.cache.get fail");
    })

    .pipe(function(){
      ok(true, "app.cache.remove done");
      return app.cache.get(original_cache.url);
    }, function(){
      ok(false, "app.cache.remove fail");
    })

    .pipe(function(){
      ok(false, "app.cache.get done");
    }, function(){
      ok(true, "app.cache.get fail");
    })

    .always(function(){
      start();
    });
});
