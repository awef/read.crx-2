`
app.history = {};

app.history.add = function(url, title) {
  var db, req_open, req_setversion, idb_transaction;

  if (!(typeof url === 'string' && typeof title === 'string')) {
    app.log('error', 'app.history.add: 引数が不正です', arguments);
    return;
  }

  idb_transaction = function() {
    var transaction;
    transaction = db.transaction(['history'],
        webkitIDBTransaction.READ_WRITE);
    transaction.oncomplete = function() {
      db.close();
    };
    transaction.onerror = function(e) {
      db.close();
      app.log('error', 'app.history.add: データの格納に失敗しました');
    };

    transaction
      .objectStore('history')
      .put({url: url, title: title, date: Date.now()});
  };

  req_open = webkitIndexedDB.open('history');
  req_open.onerror = function() {
    app.log('error', 'app.history.add: データベースへの接続に失敗');
  };
  req_open.onsuccess = function() {
    db = req_open.result;

    if (db.version === '1') {
      idb_transaction();
    }
    else {
      req_setversion = db.setVersion('1');
      req_setversion.onerror = function() {
        app.log('error', 'app.history.add: db.setVersion失敗(%s -> %s)',
                db.version, '1');
      };
      req_setversion.onsuccess = function() {
        db.createObjectStore('history', {autoIncrement: true})
          .createIndex('date', 'date');

        app.log('info', 'app.history.add: db.setVersion成功(%s -> %s)',
                db.version, '1');
        idb_transaction();
      };
    }
  };
};

app.history.get = function(offset, count, callback) {
  var req_open = webkitIndexedDB.open('history');
  req_open.onerror = function() {
    callback({status: 'error'});
    app.log('error', 'app.history.get: データベースへの接続に失敗');
  };
  req_open.onsuccess = function() {
    var db, object_store, req_cursor, transaction, data;

    db = req_open.result;
    data = [];

    if (db.version === '1') {
      transaction = db.transaction(['history'],
          webkitIDBTransaction.READ_ONLY);
      object_store = transaction.objectStore('history');
      req_cursor = object_store
                              .index('date')
                              .openCursor(null, webkitIDBCursor.PREV);
      req_cursor.onsuccess = function() {
        var cursor = req_cursor.result;
        if (cursor) {
          data.push(cursor.value);
          cursor.continue();
        }
      };

      transaction.onerror = function() {
        db.close();
        app.log('error', 'app.history.get: トランザクション中断');
        callback({status: 'error'});
      };
      transaction.oncomplete = function() {
        db.close();
        callback({status: 'success', data: data});
      };
    }
    else {
      db.close();
      app.log('warn', 'app.history.get: 非対応のdb.version %s', db.version);
    }
  };
};
`
