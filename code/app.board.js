app.board = {};

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
