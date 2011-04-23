`
module('app.bbsmenu');

test('パースエラーテスト', function() {
  strictEqual(app.bbsmenu.parse(''), null, '空文字列');
});
`
