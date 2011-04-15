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
    var guess_result = app.url.guess_type(message.url);

    if (guess_result.type === 'board') {
      app.view.open_board(message.url);
    }
    else if (guess_result.type === 'thread') {
      app.view.open_thread(message.url);
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
