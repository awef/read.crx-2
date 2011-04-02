app.cache = {};

app.cache.get = function(url, callback) {
  var db, req, tra, objectStore;

  req = webkitIndexedDB.open('cache');
  req.onerror= function() {
    callback({status: 'error'});
    app.log('error', 'app.cache.get: indexedDB.openに失敗');
  };
  req.onsuccess = function(e) {
    db = req.result;
    if (db.version === '1') {
      tra = db.transaction(['cache'], webkitIDBTransaction.READ_ONLY);
      tra.oncomplete = function(e) {
        db.close();
      };
      tra.onerror = function() {
        db.close();
      };

      objectStore = tra.objectStore('cache');
      req = objectStore.get(url);
      req.onsuccess = function(e) {
        if (typeof req.result === 'object') {
          callback({status: 'success', data: req.result})
        }
        else {
          callback({status: 'not_found'});
        }
      };
      req.onerror = function() {
        callback({status: 'error'});
      };
    }
    else {
      callback({status: 'error'});
      app.log('warn', 'app.cache.get: 予期せぬdb.version %s', db.version);
      db.close();
    }
  };
};

app.cache.set = function(data, callback) {
  var db, req, tra, objectStore;

  if (!(
    typeof data.url === 'string' &&
    typeof data.data === 'string' &&
    typeof data.last_modified === 'number' &&
    typeof data.last_updated === 'number'
  )) {
    app.log('error', 'app.cache.set: 引数が不正です');
    callback({status: 'error'});
    return;
  }

  req = webkitIndexedDB.open('cache');
  req.onerror= function() {
    callback({status: 'error'});
    app.log('error', 'app.cache.set: indexedDB.openに失敗');
  };
  req.onsuccess = function(e) {
    var version;

    db = req.result;

    version = parseInt(db.version, 10);
    if (isNaN(version) || version < 1) {
      req = db.setVersion('1');
      req.onerror = function() {
        callback({status: 'error'});
        app.log(
          'error',
          'app.cache.set: db.setVersion失敗(%s -> %s)',
          db.version,
          '1'
        );
        db.close();
      };
      req.onsuccess = function(e) {
        db.createObjectStore('cache', {keyPath: 'url'});
        app.log(
          'info',
          'app.cache.set: db.setVersion成功(%s -> %s)',
          db.version,
          '1'
        );
      };
    }

    tra = db.transaction(['cache'], webkitIDBTransaction.READ_WRITE);
    tra.oncomplete = function() {
      callback({status: 'success'});
      db.close();
    };
    tra.onerror = function() {
      callback({status: 'error'});
      db.close();
    };

    objectStore = tra.objectStore('cache');
    req = objectStore.put(data);
  };
};
