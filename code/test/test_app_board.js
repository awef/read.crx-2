module('app.board');

(function() {
  var jbbs_url, jbbs_text, jbbs_expected;

  jbbs_url = 'http://jbbs.livedoor.jp/computer/42710/';
  jbbs_text = [
    '1290070091.cgi,read.crx総合 part2(354)',
    '1290070123.cgi,read.crx CSSスレ(31)',
    '1273802908.cgi,read.crx総合(1000)',
    '1273732874.cgi,テストスレ(413)',
    '1273734819.cgi,スレスト(1)',
    '1290070091.cgi,read.crx総合 part2(354)'
  ].join('\n');
  jbbs_expected = [
    {
      url: 'http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1290070091/',
      title: 'read.crx総合 part2',
      res_count: 354
    },
    {
      url: 'http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1290070123/',
      title: 'read.crx CSSスレ',
      res_count: 31
    },
    {
      url: 'http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/',
      title: 'read.crx総合',
      res_count: 1000
    },
    {
      url: 'http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273732874/',
      title: 'テストスレ',
      res_count: 413
    },
    {
      url: 'http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273734819/',
      title: 'スレスト',
      res_count: 1
    }
  ];

  test('実例パーステスト', function() {
    deepEqual(app.board.parse(jbbs_url, jbbs_text), jbbs_expected);
  });
})();
