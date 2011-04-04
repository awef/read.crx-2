app.thread = {};

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
