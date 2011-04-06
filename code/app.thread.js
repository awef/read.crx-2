app.thread = {};

app.thread._get_xhr_info = function(thread_url) {
  var tmp;

  tmp = /^http:\/\/(\w+\.(\w+\.\w+))\/(?:test|bbs)\/read\.cgi\/(\w+)\/(\d+)\/(?:(\d+)\/)?$/.exec(thread_url);
  switch (tmp[2]) {
    case 'machi.to':
      return {
        path: 'http://' + tmp[1] + '/bbs/offlaw.cgi/' +
            tmp[3] + '/' + tmp[4] + '/',
        charset: 'Shift_JIS'
      };
    case 'livedoor.jp':
      return {
        path: 'http://jbbs.livedoor.jp/bbs/rawmode.cgi/' +
            tmp[3] + '/' + tmp[4] + '/' + tmp[5] + '/',
        charset: 'EUC-JP'
      };
    default:
      return {
        path: 'http://' + tmp[1] + '/' + tmp[3] + '/dat/' +
            tmp[4] + '.dat',
        charset: 'Shift_JIS'
      };
  }
};

app.thread.get = function(url, callback) {
  var xhr, xhr_timer, xhr_path, xhr_charset, last_modified, thread, tmp;

  tmp = app.thread._get_xhr_info(url);
  xhr_path = tmp.path;
  xhr_charset = tmp.charset;

  app.cache.get(xhr_path, function(cache) {
    if (cache.status === 'success' &&
        Date.now() - cache.data.last_updated < 1000 * 60) {
      callback({
        status: 'success',
        data: app.thread.parse(url, cache.data.data)
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
              (thread = app.thread.parse(url, xhr.responseText)) &&
              thread.res.length > 0
          ) {
            callback({status: 'success', data: thread});

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
                data: app.thread.parse(url, cache.data.data)
              });
              cache.data.last_updated = Date.now();
              app.cache.set(cache.data);
            }
            else {
              callback({
                status: 'error',
                data: app.thread.parse(url, cache.data.data)
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

app.thread.parse = function(url, text) {
  var tmp;

  tmp = /^http:\/\/\w+\.(\w+\.\w+)\//.exec(url);
  if (tmp[1] === 'machi.to') {
    return app.thread._parse_machi(text);
  }
  else if (tmp[1] === 'livedoor.jp') {
    return app.thread._parse_jbbs(text);
  }
  else {
    return app.thread._parse_ch(text);
  }
};

app.thread._parse_ch = function(text) {
  var reg, reg_res, thread, first_flg;

  //name, mail, other, message, thread_title
  reg = /^(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm;

  thread = {res: []};
  first_flg = true;
  while (reg_res = reg.exec(text)) {
    if (first_flg) {
      thread.title = reg_res[5];
      first_flg = false;
    }
    thread.res.push({
      name: reg_res[1],
      mail: reg_res[2],
      message: reg_res[4],
      other: reg_res[3]
    });
  }
  return thread;
};

app.thread._parse_machi = function(text) {
  var reg, reg_res, thread, res_count;

  //res_num, name, mail, other, message, thread_title
  reg = /^(\d+)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm;

  thread = {res: []};
  res_count = 0;
  while (reg_res = reg.exec(text)) {
    while (++res_count !== +reg_res[1]) {
      thread.res.push({
        name: 'あぼーん',
        mail: 'あぼーん',
        message: 'あぼーん',
        other: 'あぼーん'
      });
    }

    if (res_count === 1) {
      thread.title = reg_res[6];
    }
    thread.res.push({
      name: reg_res[2],
      mail: reg_res[3],
      message: reg_res[5],
      other: reg_res[4]
    });
  }
  return thread;
};

app.thread._parse_jbbs = function(text) {
  var reg, reg_res, thread, res_count;

  //res_num, name, mail, date, message, thread_title, id
  reg = /^(\d+)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)<>(.*)$/gm;

  thread = {res: []};
  res_count = 0;
  while (reg_res = reg.exec(text)) {
    while (++res_count !== +reg_res[1]) {
      thread.res.push({
        name: 'あぼーん',
        mail: 'あぼーん',
        message: 'あぼーん',
        other: 'あぼーん'
      });
    }

    if (res_count === 1) {
      thread.title = reg_res[6];
    }
    thread.res.push({
      name: reg_res[2],
      mail: reg_res[3],
      message: reg_res[5],
      other: reg_res[4] + ' ID:' + reg_res[7]
    });
  }
  return thread;
};
