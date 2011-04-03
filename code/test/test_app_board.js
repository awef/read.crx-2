module('app.board');

(function() {
  var machi_url, machi_text, machi_expected,
      jbbs_url, jbbs_text, jbbs_expected;

  machi_url = 'http://www.machi.to/tawara/';
  machi_text = [
    '1<>1269441710<>～削除依頼はこちらから～(1)',
    '2<>1299160555<>関東板削除依頼スレッド54(134)',
    '3<>1239604919<>●ホスト規制中第32巻●(973)',
    '4<>1300530242<>東北板　削除依頼スレッド【Part38】(210)',
    '5<>1187437274<>東北板管理人**********不信任スレ(350)'
  ].join('\n');
  machi_expected = [
    {
      url: 'http://www.machi.to/bbs/read.cgi/tawara/1269441710/',
      title: '～削除依頼はこちらから～',
      res_count: 1
    },
    {
      url: 'http://www.machi.to/bbs/read.cgi/tawara/1299160555/',
      title: '関東板削除依頼スレッド54',
      res_count: 134
    },
    {
      url: 'http://www.machi.to/bbs/read.cgi/tawara/1239604919/',
      title: '●ホスト規制中第32巻●',
      res_count: 973
    },
    {
      url: 'http://www.machi.to/bbs/read.cgi/tawara/1300530242/',
      title: '東北板　削除依頼スレッド【Part38】',
      res_count: 210
    },
    {
      url: 'http://www.machi.to/bbs/read.cgi/tawara/1187437274/',
      title: '東北板管理人**********不信任スレ',
      res_count: 350
    }
  ];

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
    deepEqual(app.board.parse(machi_url, machi_text), machi_expected);
    deepEqual(app.board.parse(jbbs_url, jbbs_text), jbbs_expected);
  });
})();
