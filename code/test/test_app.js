module('app.deep_copy');

test('test', function() {
  var original, copy;

  original = {test: 123};
  copy = original;
  strictEqual(original, copy, 'シャローコピーはオリジナルとstrictEqual');
  copy.test = 321;
  deepEqual(original, copy,
      'シャローコピーはただの別名なので、変更も共有される');

  original = {test: 123};
  copy = app.deep_copy(original);
  notStrictEqual(original, copy,
      'ディープコピーはオリジナルとstrictEqualにならない');
  deepEqual(original, copy, 'ディープコピーはオリジナルと構造は一緒');
  copy.test = 321;
  notDeepEqual(original, copy,
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
  notStrictEqual(original, copy,
      'ディープコピーはオリジナルとstrictEqualにならない２');
  deepEqual(original, copy, 'ディープコピーはオリジナルと構造は一緒２');
});
