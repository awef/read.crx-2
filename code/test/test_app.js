module('app.deep_copy');

test('test', 7, function() {
  var original, copy;

  original = {test: 123};
  copy = original;
  strictEqual(copy, original, 'シャローコピーはオリジナルとstrictEqual');
  copy.test = 321;
  deepEqual(copy, original,
      'シャローコピーはただの別名なので、変更も共有される');

  original = {test: 123};
  copy = app.deep_copy(original);
  notStrictEqual(copy, original,
      'ディープコピーはオリジナルとstrictEqualにならない');
  deepEqual(copy, original, 'ディープコピーはオリジナルと構造は一緒');
  copy.test = 321;
  notDeepEqual(copy, original,
      'ディープコピーの編集はオリジナルに影響しない');

  original = {
    test1: 123,
    test2: '123',
    test3: [1, 2, 3.14],
    test4: {
      test5: 123,
      test6: 'テスト',
      test7: [
        {test8: Math.PI}
      ]
    }
  };
  copy = app.deep_copy(original);
  notStrictEqual(copy, original,
      'ディープコピーはオリジナルとstrictEqualにならない２');
  deepEqual(copy, original, 'ディープコピーはオリジナルと構造は一緒２');
});


module('app.message');

test('test', 3, function() {
  app.message.add_listener('__test1', function(message) {
    strictEqual(message, 'test', '基本送信テスト');
  });
  app.message.send('__test1', 'test');

  app.message.add_listener('__test2', function(message) {
    deepEqual(message, {test: 123}, 'メッセージの編集テスト');
    message.hoge = 345;
  });
  app.message.add_listener('__test2', function(message) {
    deepEqual(message, {test: 123}, 'メッセージの編集テスト');
    message.hoge = 345;
  });
  app.message.send('__test2', {test: 123});
});

module('app.url');

test('app.url.fix', function() {
  var test_board_url, test_thread_url;

  test_board_url = function(fixed_url, service) {
    strictEqual(app.url.fix(fixed_url), fixed_url, service + ' 板URL');
    strictEqual(app.url.fix(fixed_url + '#5'), fixed_url, service + ' 板URL');
  };

  test_thread_url = function(fixed_url, service) {
    strictEqual(app.url.fix(fixed_url), fixed_url, service + ' スレッドURL');
    strictEqual(app.url.fix(fixed_url.slice(0, -1)), fixed_url, service + ' スレッドURL');
    strictEqual(app.url.fix(fixed_url + 'l50'), fixed_url, service + ' スレッドURL');
    strictEqual(app.url.fix(fixed_url + '50'), fixed_url, service + ' スレッドURL');
    strictEqual(app.url.fix(fixed_url + '50/'), fixed_url, service + ' スレッドURL');
    strictEqual(app.url.fix(fixed_url + '50-100'), fixed_url, service + ' スレッドURL');
  }

  test_board_url('http://qb5.2ch.net/operate/', '2ch');
  test_thread_url('http://pc11.2ch.net/test/read.cgi/hp/1277348045/', '2ch');

  test_board_url('http://www.machi.to/tawara/', 'まちBBS');
  test_thread_url('http://www.machi.to/bbs/read.cgi/tawara/511234524356/', 'まちBBS');

  test_board_url('http://jbbs.livedoor.jp/computer/42710/', 'したらば');
  test_thread_url('http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/', 'したらば');

  test_board_url('http://pele.bbspink.com/erobbs/', 'BBSPINK');
  test_thread_url('http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/', 'BBSPINK');

  test_board_url('http://ex14.vip2ch.com/part4vip/', 'パー速');
  test_thread_url('http://ex14.vip2ch.com/test/read.cgi/part4vip/1291628400/', 'パー速');

  strictEqual(app.url.fix('bookmark'), 'bookmark', 'bookmark');
  strictEqual(app.url.fix('history'), 'history', 'history');
  strictEqual(app.url.fix('kakikomi_log'), 'kakikomi_log', 'kakikomi_log');
});

test('app.url.guess_type', function() {
  var hoge;

  hoge = function(url, expected) {
    deepEqual(app.url.guess_type(url), expected, url);
  };

  hoge('http://qb5.2ch.net/operate/', {type: 'board', bbs_type: '2ch'});
  hoge('http://pc11.2ch.net/test/read.cgi/hp/1277348045/', {type: 'thread', bbs_type: '2ch'});

  hoge('http://www.machi.to/tawara/', {type: 'board', bbs_type: 'machi'});
  hoge('http://www.machi.to/bbs/read.cgi/tawara/511234524356/', {type: 'thread', bbs_type: 'machi'});

  hoge('http://jbbs.livedoor.jp/computer/42710/', {type: 'board', bbs_type: 'jbbs'});
  hoge('http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/', {type: 'thread', bbs_type: 'jbbs'});

  hoge('http://pele.bbspink.com/erobbs/', {type: 'board', bbs_type: '2ch'});
  hoge('http://pele.bbspink.com/test/read.cgi/erobbs/9241103704/', {type: 'thread', bbs_type: '2ch'});

  hoge('http://ex14.vip2ch.com/part4vip/', {type: 'board', bbs_type: '2ch'});
  hoge('http://ex14.vip2ch.com/test/read.cgi/part4vip/1291628400/', {type: 'thread', bbs_type: '2ch'});

  hoge('http://example.com/', {type: 'unknown', bbs_type: 'unknown'});
});
