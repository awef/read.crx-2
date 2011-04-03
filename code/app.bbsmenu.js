app.bbsmenu = {};

app.bbsmenu.get = function(callback) {
  var url, xhr, xhr_timer, menu;

  url = 'http://menu.2ch.net/bbsmenu.html';

  app.cache.get(url, function(cache) {
    if (cache.status === 'success' &&
        Date.now() - cache.data.last_updated < 1000 * 60 * 60 * 12) {
      menu = app.bbsmenu.parse(cache.data.data);
      callback({status: 'success', data: menu});
    }
    else {
      xhr = new XMLHttpRequest();
      xhr_timer = setTimeout(function() { xhr.abort(); }, 1000 * 30);
      xhr.onreadystatechange = function() {
        var last_modified;

        if (xhr.readyState === 4) {
          clearTimeout(xhr_timer);

          if (
              xhr.status === 200 &&
              (menu = app.bbsmenu.parse(this.responseText)) &&
              menu.length > 0
          ) {
            callback({status: 'success', data: menu});

            last_modified = new Date(
                xhr.getResponseHeader('Last-Modified') || 'dummy')
              .getTime();
            if (!isNaN(last_modified)) {
              app.cache.set({
                url: url,
                data: xhr.responseText,
                last_updated: Date.now(),
                last_modified: last_modified
              });
            }
          }
          else if (cache.status === 'success') {
            callback({
              status: xhr.status === 304 ? 'success' : 'error',
              data: app.bbsmenu.parse(cache.data.data)
            });
          }
          else {
            callback({status: 'error'});
          }
        }
      };
      xhr.overrideMimeType('text/plain; charset=Shift_JIS');
      xhr.open('GET', url + '?_=' + Date.now().toString(10));
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

app.bbsmenu.parse = function(html) {
  var reg_category,
      reg_board,
      reg_category_res,
      reg_board_res,
      menu,
      category;

  reg_category = /<b>(.+?)<\/b>(?:.*\n<a .*?>.+?<\/a>)+/gi;
  reg_board = /<a href=(http:\/\/(?!info\.2ch\.net\/)\w+\.(?:2ch\.net|machi\.to)\/\w+\/)(?:\s.*?)?>(.+?)<\/a>/gi;

  menu = [];

  while (reg_category_res = reg_category.exec(html)) {
    category = {};
    category.title = reg_category_res[1];
    category.board = [];

    while (reg_board_res = reg_board.exec(reg_category_res[0])) {
      category.board.push({
        url: reg_board_res[1],
        title: reg_board_res[2]
      });
    }

    if (category.board.length > 0) {
      menu.push(category);
    }
  }

  return menu;
};
