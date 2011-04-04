app.board = {};

app.board._get_xhr_info = function(board_url) {
  var tmp;

  tmp = /^http:\/\/(\w+\.(\w+\.\w+))\/(\w+)\/(\w+)?/.exec(board_url);
  if (tmp[2] === 'machi.to') {
    return {
      path: 'http://' + tmp[1] + '/bbs/offlaw.cgi/' + tmp[3] + '/',
      charset: 'Shift_JIS'
    };
  }
  else if (tmp[2] === 'livedoor.jp') {
    return {
      path: 'http://jbbs.livedoor.jp/' +
          tmp[3] + '/' +
          tmp[4] + '/subject.txt',
      charset: 'EUC-JP'
    };
  }
  else {
    return {
      path: 'http://' + tmp[1] + '/' + tmp[3] + '/subject.txt',
      charset: 'Shift_JIS'
    };
  }
};

app.board.get = function(url, callback) {
  var xhr, xhr_timer, xhr_path, xhr_charset, last_modified, board, tmp;

  tmp = app.board._get_xhr_info(url);
  xhr_path = tmp.path;
  xhr_charset = tmp.charset;

  app.cache.get(xhr_path, function(cache) {
    if (cache.status === 'success' &&
        Date.now() - cache.data.last_updated < 1000 * 60) {
      callback({
        status: 'success',
        data: app.board.parse(url, cache.data.data)
      });
    }
    else {
      xhr = new XMLHttpRequest();
      xhr_timer = setTimeout(function() { xhr.abort(); }, 1000 * 30);
      xhr.onreadystatechange = function() {
        if (xhr.readyState === 4) {
          clearTimeout(xhr_timer);

          if (
              xhr.status === 200 &&
              (board = app.board.parse(url, xhr.responseText)) &&
              board.length > 0
          ) {
            callback({success: 'success', data: board});

            last_modified = new Date(
                xhr.getResponseHeader('Last-Modified') || 'dummy')
              .getTime();
            if (!isNaN(last_modified)) {
              app.cache.set({
                url: xhr_path,
                data: xhr.responseText,
                last_updated: Date.now(),
                last_modified: last_modified
              });
            }
          }
          else if (cache.status === 'success') {
            if (xhr.status === 304) {
              callback({
                status: 'success',
                data: app.board.parse(url, cache.data.data)
              });
              cache.data.last_updated = Date.now();
              app.cache.set(cache.data);
            }
            else {
              callback({
                status: 'error',
                data: app.board.parse(url, cache.data.data)
              });
            }
          }
          else {
            callback({status: 'error'});
          }
        }
      };
      xhr.overrideMimeType('text/plain; charset=' + xhr_charset);
      xhr.open('GET', xhr_path + '?_=' + Date.now().toString(10));
      if (cache.status === 'success') {
        xhr.setRequestHeader(
            'If-Modified-Since',
            new Date(cache.data.last_modified).toUTCString()
        );
      }
      xhr.send(null);
    }
  });
};

app.board.parse = function(url, text) {
  var tmp,
      bbs_type,
      reg,
      reg_res,
      base_url,
      board;

  tmp = /^http:\/\/(\w+\.(\w+\.\w+))\/(\w+)\/(\w+)?/.exec(url);
  if (tmp[2] === 'machi.to') {
    bbs_type = 'machi';
    reg = /^\d+<>(\d+)<>(.+)\((\d+)\)$/gm;
    base_url = 'http://' +
        tmp[1] +
        '/bbs/read.cgi/' +
        tmp[3] +
        '/';
  }
  else if (tmp[2] === 'livedoor.jp') {
    bbs_type = 'jbbs';
    reg = /^(\d+)\.cgi,(.+)\((\d+)\)$/gm;
    base_url = 'http://jbbs.livedoor.jp/bbs/read.cgi/' +
        tmp[3] +
        '/' +
        tmp[4] +
        '/';
  }
  else {
    bbs_type = '2ch';
    reg = /^(\d+)\.dat<>(.+) \((\d+)\)$/gm;
    base_url = 'http://' +
        tmp[1] +
        '/test/read.cgi/' +
        tmp[3] +
        '/';
  }

  board = [];
  while (reg_res = reg.exec(text)) {
    board.push({
      url: base_url + reg_res[1] + '/',
      title: reg_res[2],
      res_count: +reg_res[3]
    });
  }

  if (bbs_type === 'jbbs') {
    board.splice(-1, 1);
  }

  return board;
};
