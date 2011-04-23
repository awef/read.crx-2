`
module('app.thread');

test('app.thread._get_xhr_info', function() {
  deepEqual(
      app.thread._get_xhr_info('http://qb5.2ch.net/test/read.cgi/operate/1234567890/'),
      {
        path: 'http://qb5.2ch.net/operate/dat/1234567890.dat',
        charset: 'Shift_JIS'
      },
      '2ch'
  );

  deepEqual(
      app.thread._get_xhr_info('http://www.machi.to/bbs/read.cgi/tawara/511234524356/'),
      {
        path: 'http://www.machi.to/bbs/offlaw.cgi/tawara/511234524356/',
        charset: 'Shift_JIS'
      },
      'まちBBS'
  );


  deepEqual(
      app.thread._get_xhr_info('http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273732874/'),
      {
        path: 'http://jbbs.livedoor.jp/bbs/rawmode.cgi/computer/42710/1273732874/',
        charset: 'EUC-JP'
      },
      'したらば'
  );

  deepEqual(
      app.thread._get_xhr_info('http://pele.bbspink.com/test/read.cgi/erobbs/1297500876/'),
      {
        path: 'http://pele.bbspink.com/erobbs/dat/1297500876.dat',
        charset: 'Shift_JIS'
      },
      'BBSPINK'
  );

  deepEqual(
      app.thread._get_xhr_info('http://ex14.vip2ch.com/test/read.cgi/part4vip/1289640497/'),
      {
        path: 'http://ex14.vip2ch.com/part4vip/dat/1289640497.dat',
        charset: 'Shift_JIS'
      },
      'パー速'
  );

  strictEqual(app.thread._get_xhr_info(''), null, '空URL');
  strictEqual(app.thread._get_xhr_info('awsedtfgyuhjikolp;'), null, 'ダミー文字列');
  strictEqual(app.thread._get_xhr_info('http://example.com/'), null, 'いずれのタイプの掲示板にも当てはまらないURL');
  strictEqual(app.thread._get_xhr_info('http://example.com/test/hogehoge/fugafuga/'), null, 'いずれのタイプの掲示板にも当てはまらないURL 2');
});

(function() {
  var ch_url, ch_text, ch_expected,
      machi_url, machi_text, machi_expected,
      jbbs_url, jbbs_text, jbbs_expected;

  ch_url = 'http://qb5.2ch.net/test/read.cgi/operate/1234567890/';
  ch_text = [
    'ﾉtasukeruyo </b>忍法帖【Lv=10,xxxPT】<b> </b>◆0a./bc.def <b><><>2011/04/04(月) 10:19:46.92 ID:abcdEfGH0 BE:1234567890-2BP(1)<> テスト。 <br> http://qb5.2ch.net/test/read.cgi/operate/132452341234/1 <br> <hr><font color="blue">Monazilla/1.00 (V2C/2.5.1)</font> <>[test] テスト 123 [ﾃｽﾄ]',
    ' </b>【東電 84.2 %】<b>  </b>◆0a./bc.def <b><>sage<>2011/04/04(月) 10:21:08.27 ID:abcdEfGH0<> てすとてすとテスト! <>',
    ' </b>忍法帖【Lv=11,xxxPT】<b> <>sage<>2011/04/04(月) 10:24:46.33 ID:abc0DEFG1<> <a href="../test/read.cgi/operate/1234567890/1" target="_blank">&gt;&gt;1</a> <br> 乙 <br> てすとてすと試験てすと <>',
    '動け動けウゴウゴ２ちゃんねる<>sage<>2011/04/04(月) 10:25:17.27 ID:ABcdefgh0<> てすと、テスト <>',
    '動け動けウゴウゴ２ちゃんねる<><>2011/04/04(月) 10:25:51.88 ID:aBcdEfg+0<> てす <>'
  ].join('\n');
  ch_expected = {
    title: '[test] テスト 123 [ﾃｽﾄ]',
    res: [
      {
        name: 'ﾉtasukeruyo </b>忍法帖【Lv=10,xxxPT】<b> </b>◆0a./bc.def <b>',
        mail: '',
        message: ' テスト。 <br> http://qb5.2ch.net/test/read.cgi/operate/132452341234/1 <br> <hr><font color="blue">Monazilla/1.00 (V2C/2.5.1)</font> ',
        other: '2011/04/04(月) 10:19:46.92 ID:abcdEfGH0 BE:1234567890-2BP(1)'
      },
      {
        name: ' </b>【東電 84.2 %】<b>  </b>◆0a./bc.def <b>',
        mail: 'sage',
        message: ' てすとてすとテスト! ',
        other: '2011/04/04(月) 10:21:08.27 ID:abcdEfGH0'
      },
      {
        name: ' </b>忍法帖【Lv=11,xxxPT】<b> ',
        mail: 'sage',
        message: ' <a href="../test/read.cgi/operate/1234567890/1" target="_blank">&gt;&gt;1</a> <br> 乙 <br> てすとてすと試験てすと ',
        other: '2011/04/04(月) 10:24:46.33 ID:abc0DEFG1'
      },
      {
        name: '動け動けウゴウゴ２ちゃんねる',
        mail: 'sage',
        message: ' てすと、テスト ',
        other: '2011/04/04(月) 10:25:17.27 ID:ABcdefgh0'
      },
      {
        name: '動け動けウゴウゴ２ちゃんねる',
        mail: '',
        message: ' てす ',
        other: '2011/04/04(月) 10:25:51.88 ID:aBcdEfg+0'
      }
    ]
  };

  //削除時の挙動確認用に>>3-4を削除
  //メール欄の確認用に>>5を改変
  machi_url = 'http://www.machi.to/bbs/read.cgi/tawara/511234524356/';
  machi_text = [
    '1<>まちこさん<><>2007/06/10(日) 09:20:35 ID:aBC.DeFG<>テストテストテスト。<br><br>sage推奨<>【test】色々testスレ（トリップテストとか）【テスト】　７題目',
    '2<>◆</b>1a2BC3DeFg<b><><>2007/06/11(月) 22:33:18 ID:Ab0cdeFG<>あ　い　う　え　tesu<>',
    //'3<>◆</b>leaf.0HM.6<b><><>2007/06/11(月) 22:36:54 ID:Ab0cdeFG<>あ　い　う　え　tesu２<>',
    //'4<>まちこさん<>sage<>2007/06/13(水) 12:14:13 ID:eaBLq6ow<>check test<>',
    //'5<>◆</b>abcd.EfGHI<b><><>2007/06/13(水) 14:49:19 ID:aBcdEfgH<>あ　い　う　え　tesu３<>'
    '5<>◆</b>abcd.EfGHI<b><>sage<>2007/06/13(水) 14:49:19 ID:aBcdEfgH<>あ　い　う　え　tesu３<>'
  ].join('\n');
  machi_expected = {
    title: '【test】色々testスレ（トリップテストとか）【テスト】　７題目',
    res: [
      {
        name: 'まちこさん',
        mail: '',
        message: 'テストテストテスト。<br><br>sage推奨',
        other: '2007/06/10(日) 09:20:35 ID:aBC.DeFG'
      },
      {
        name: '◆</b>1a2BC3DeFg<b>',
        mail: '',
        message: 'あ　い　う　え　tesu',
        other: '2007/06/11(月) 22:33:18 ID:Ab0cdeFG'
      },
      {
        name: 'あぼーん',
        mail: 'あぼーん',
        message: 'あぼーん',
        other: 'あぼーん'
      },
      {
        name: 'あぼーん',
        mail: 'あぼーん',
        message: 'あぼーん',
        other: 'あぼーん'
      },
      {
        name: '◆</b>abcd.EfGHI<b>',
        mail: 'sage',
        message: 'あ　い　う　え　tesu３',
        other: '2007/06/13(水) 14:49:19 ID:aBcdEfgH'
      }
    ]
  };

  //削除時の挙動確認用に>>3-4を削除
  jbbs_url = 'http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1290070091/';
  jbbs_text = [
    '1<><font color=#FF0000>awef★</font><><>2010/11/18(木) 17:48:11<>read.crxについての質問・要望・不具合報告等を気楽に書き込んで下さい<br><br>インストールはこちらから<br>ttps://chrome.google.com/extensions/detail/hhjpdicibjffnpggdiecaimdgdghainl<br>関連文章<br>ttp://wiki.livedoor.jp/awef/d/read.crx<br>UserVoice<br>ttp://readcrx.uservoice.com/<br>前スレ<br>ttp://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/<br><br>既出の要望・バグ等は全てUserVoiceで管理します<br>直接UserVoiceに投稿しちゃっても構いません<>read.crx総合 part2<>???',
    '2<>名無しさん<><>2010/12/03(金) 02:50:42<>ttp://wikiwiki.jp/readcrx/<br>非公式のread.crx wikiです<br>ユーザーCSS等の投稿用にどうぞ。<br><br>&gt;&gt;前スレ999-1000<br>スレ覧のブックマークは固定して、ボード覧からは削除したらどうでしょうか<><>ABCD0eFg',
    //'3<>名無しさん<>sage<>2010/12/04(土) 21:47:14<>ブックマークといえば、板自体も追加できるようになってほしいな<br>それかフィルタ／検索できればうれしい<><>RH1hBnWQ',
    //'4<>名無しさん<>sage<>2010/12/04(土) 22:24:03<>ちょっと特殊だけど、新月って掲示板にも対応して欲しいです<br><br><a href="/bbs/read.cgi/computer/42710/1290070091/3" target="_blank">&gt;&gt;3</a><br>え？既にできるぞ<><>ojq4NrdU',
    '5<>名無しさん<>sage<>2010/12/04(土) 22:57:40<><a href="/bbs/read.cgi/computer/42710/1290070091/2" target="_blank">&gt;&gt;2</a><br>少なくとも、今のブックマーク表示は、他の板とそれ程区別する必要は無いと思ってます<br><br><a href="/bbs/read.cgi/computer/42710/1290070091/4" target="_blank">&gt;&gt;4</a><br>サッとプロトコル見てみましたけど、多分無理っすね<br>こちら側も鯖立てないとムリっぽいし<><>.aBCefGh'
  ].join('\n');
  jbbs_expected = {
    title: 'read.crx総合 part2',
    res: [
      {
        name: '<font color=#FF0000>awef★</font>',
        mail: '',
        message: 'read.crxについての質問・要望・不具合報告等を気楽に書き込んで下さい<br><br>インストールはこちらから<br>ttps://chrome.google.com/extensions/detail/hhjpdicibjffnpggdiecaimdgdghainl<br>関連文章<br>ttp://wiki.livedoor.jp/awef/d/read.crx<br>UserVoice<br>ttp://readcrx.uservoice.com/<br>前スレ<br>ttp://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/1273802908/<br><br>既出の要望・バグ等は全てUserVoiceで管理します<br>直接UserVoiceに投稿しちゃっても構いません',
        other: '2010/11/18(木) 17:48:11 ID:???'
      },
      {
        name: '名無しさん',
        mail: '',
        message: 'ttp://wikiwiki.jp/readcrx/<br>非公式のread.crx wikiです<br>ユーザーCSS等の投稿用にどうぞ。<br><br>&gt;&gt;前スレ999-1000<br>スレ覧のブックマークは固定して、ボード覧からは削除したらどうでしょうか',
        other: '2010/12/03(金) 02:50:42 ID:ABCD0eFg'
      },
      {
        name: 'あぼーん',
        mail: 'あぼーん',
        message: 'あぼーん',
        other: 'あぼーん'
      },
      {
        name: 'あぼーん',
        mail: 'あぼーん',
        message: 'あぼーん',
        other: 'あぼーん'
      },
      {
        name: '名無しさん',
        mail: 'sage',
        message: '<a href="/bbs/read.cgi/computer/42710/1290070091/2" target="_blank">&gt;&gt;2</a><br>少なくとも、今のブックマーク表示は、他の板とそれ程区別する必要は無いと思ってます<br><br><a href="/bbs/read.cgi/computer/42710/1290070091/4" target="_blank">&gt;&gt;4</a><br>サッとプロトコル見てみましたけど、多分無理っすね<br>こちら側も鯖立てないとムリっぽいし',
        other: '2010/12/04(土) 22:57:40 ID:.aBCefGh'
      }
    ]
  };

  test('実例パーステスト', function() {
    deepEqual(app.thread.parse(ch_url, ch_text), ch_expected, '2ch');
    deepEqual(app.thread.parse(machi_url, machi_text), machi_expected, 'まちBBS');
    deepEqual(app.thread.parse(jbbs_url, jbbs_text), jbbs_expected, 'したらば');
  });

  test('パースエラーテスト', function() {
    strictEqual(app.thread.parse(ch_url, ''), null, '2ch系URL + 空dat');
    strictEqual(app.thread.parse(machi_url, ''), null, 'まちBBS系URL + 空dat');
    strictEqual(app.thread.parse(jbbs_url, ''), null, 'したらば系URL + 空dat');
  });
})();
`
