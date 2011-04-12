(function() {
  var xhr, manifest, reg_res, query;

  if (location.pathname !== '/app.html') {
    return;
  }

  xhr = new XMLHttpRequest();
  xhr.open('GET', '/manifest.json', false);
  xhr.send(null);
  manifest = JSON.parse(xhr.responseText);

  if (manifest.version !==
      document.documentElement.getAttribute('data-app-version')) {
    location.reload(true);
  }

  reg_res = /[\?&]q=([^&]+)/.exec(location.search);
  query = reg_res ? reg_res[1] : 'app';

  chrome.tabs.getCurrent(function(current_tab) {
    chrome.windows.getAll({populate: true}, function(windows) {
      var win, win_key, tab, tab_key, app_path;

      app_path = chrome.extension.getURL('app.html');
      for (win_key = 0; win = windows[win_key]; win_key++) {
        for (tab_key = 0; tab = win.tabs[tab_key]; tab_key++) {
          if (tab.id !== current_tab.id && tab.url === app_path) {
            chrome.windows.update(win.id, {focused: true});
            chrome.tabs.update(tab.id, {selected: true});
            if (query !== 'app') {
              chrome.tabs.sendRequest(tab.id, {type: 'open', query: query});
            }
            chrome.tabs.remove(current_tab.id);
            return;
          }
        }
      }

      history.pushState(null, null, '/app.html');
      $(function() {
        app.main();
        if (query !== 'app') {
          app.message.send('open', {query: query});
        }
      });
    });
  });
})();

var app;

app = {};

app.main = function() {
  app.view.init();
  app.view.load_sidemenu();

  app.message.add_listener('open', function(message) {
    var tmp;

    tmp = app.url.guess_type(message.url);
    if (tmp.type === 'board') {
      app.view.open_board(message.url);
    }
  });
};

app.log = function(level) {
  level = level || 'log';

  if (['log', 'debug', 'info', 'warn', 'error'].indexOf(level) !== -1) {
    console[level].apply(console, Array.prototype.slice.call(arguments, 1));
  }
  else {
    app.log('error', 'app.log: 引数levelが不正な値です', arguments);
  }
};

app.deep_copy = function(data) {
  return JSON.parse(JSON.stringify(data));
};

app.message = {};
(function() {
  var listener_store = {};

  app.message.send = function(type, data) {
    var key, val;

    if (type in listener_store) {
      for (key = 0; val = listener_store[type][key]; key++) {
        val(app.deep_copy(data));
      }
    }
  };
  app.message.add_listener = function(type, fn) {
    if (!(type in listener_store)) {
      listener_store[type] = [];
    }
    listener_store[type].push(fn);
  };
})();

app.notice = {};
app.notice.push = function(text) {
  var $container;

  $('<div>')
    .append(
      $('<div>', {text: text}),
      $('<button>')
        .bind('click', function() {
            $(this)
              .parent()
                .slideUp('fast', function() {
                  $(this).remove();
                });
            })
      )
    .hide()
    .appendTo('#app_notice_container')
    .fadeIn();
};

app.url = {};
app.url.fix = function(url) {
  return url
   .replace(/^(http:\/\/[\w\.]+\/test\/read\.cgi\/\w+\/\d+).*?$/, '$1/')
   .replace(/^(http:\/\/\w+\.machi\.to\/bbs\/read\.cgi\/\w+\/\d+).*?$/, '$1/')
   .replace(/^(http:\/\/jbbs\.livedoor\.jp\/bbs\/read\.cgi\/\w+\/\d+\/\d+).*?$/, '$1/')
   .replace(/^(http:\/\/[\w\.]+\/\w+\/(?:\d+\/)?)(?:#.*)?$/, '$1');
};
app.url.guess_type = function(url) {
  url = app.url.fix(url);
  switch (true) {
    case /^http:\/\/jbbs\.livedoor\.jp\/bbs\/read\.cgi\/\w+\/\d+\/\d+\/$/
      .test(url):
      return {type: 'thread', bbs_type: 'jbbs'};
    case /^http:\/\/jbbs\.livedoor\.jp\/\w+\/\d+\/$/.test(url):
      return {type: 'board', bbs_type: 'jbbs'};
    case /^http:\/\/\w+\.machi\.to\/bbs\/read\.cgi\/\w+\/\d+\/$/.test(url):
      return {type: 'thread', bbs_type: 'machi'};
    case /^http:\/\/\w+\.machi\.to\/\w+\/$/.test(url):
      return {type: 'board', bbs_type: 'machi'};
    case /^http:\/\/[\w\.]+\/test\/read\.cgi\/\w+\/\d+\/$/.test(url):
      return {type: 'thread', bbs_type: '2ch'};
    case /^http:\/\/[\w\.]+\/\w+\/$/.test(url):
      return {type: 'board', bbs_type: '2ch'};
    default:
      return {type: 'unknown', bbs_type: 'unknown'};
  }
};

app.view = {};
app.view.init = function() {
  $('#body')
    .addClass('pane-3');

  $('#tab-a, #tab-b').tab();

  $('#tab-resizer')
    .bind('mousedown', function(e) {
      var tab_a = document.getElementById('tab-a'),
          min_height = 50,
          max_height = document.body.offsetHeight - 50;

      e.preventDefault();
      $('<div>', {css: {
          position : 'absolute',
          left: 0,
          top: 0,
          width: '100%',
          height: '100%',
          'z-index': 999,
          cursor: 'row-resize'
        }})
        .bind('mousemove', function(e) {
          tab_a.style['height'] =
            Math.max(Math.min(e.pageY, max_height), min_height) + 'px';
        })
        .bind('mouseup', function() {
          $(this).remove();
        })
        .appendTo('body');
    });

  $(document.documentElement)
    .delegate('.open_in_rcrx', 'click', function(e) {
        e.preventDefault();
        app.message.send('open', {url: this.href});
      });
};
app.view.load_sidemenu = function(url) {
  app.bbsmenu.get(function(res) {
    var frag, category, board, h3, ul, li, a;

    if ('data' in res) {
      frag = document.createDocumentFragment();
      res.data.forEach(function(category) {
        h3 = document.createElement('h3');
        h3.innerText = category.title;
        frag.appendChild(h3);

        ul = document.createElement('ul');
        category.board.forEach(function(board) {
          li = document.createElement('li');
          a = document.createElement('a');
          a.className = 'open_in_rcrx';
          a.innerText = board.title;
          a.href = board.url;
          li.appendChild(a);
          ul.appendChild(li);
        });
        frag.appendChild(ul);
      });
    }

    $('#left-pane')
      .append(frag)
      .accordion();
  });
};
app.view.open_board = function(url) {
  app.board.get(url, function(res) {
    var $container, tbody, tr, td, fn, date, now, thread_how_old;
    fn = function(a) { return (a < 10 ? '0' : '') + a; };
    now = Date.now();

    if ('data' in res) {
      $container = $('#template > .view-board').clone();
      tbody = $container.find('tbody')[0];
      res.data.forEach(function(thread) {
        tr = document.createElement('tr');

        td = document.createElement('td');
        tr.appendChild(td);

        td = document.createElement('td');
        td.innerText = thread.title;
        tr.appendChild(td);

        td = document.createElement('td');
        td.innerText = thread.res_count;
        tr.appendChild(td);

        td = document.createElement('td');
        tr.appendChild(td);

        td = document.createElement('td');
        thread_how_old = (now - thread.created_at) / (24 * 60 * 60 * 1000);
        td.innerText = (thread.res_count / thread_how_old).toFixed(1);
        tr.appendChild(td);

        td = document.createElement('td');
        date = new Date(thread.created_at);
        td.innerText = date.getFullYear() +
            '/' + fn(date.getMonth() + 1) +
            '/' + fn(date.getDate()) +
            ' ' + fn(date.getHours()) +
            ':' + fn(date.getMinutes());
        tr.appendChild(td);

        tbody.appendChild(tr);
      });
      $container.appendTo('#tab-a');

      $('#tab-a').tab('add', {element: $container[0], title: url});
    }
    else {
      alert('error');
    }
  });
};
