(() ->
  if location.pathname isnt "/app.html"
    return

  xhr = new XMLHttpRequest()
  xhr.open("GET", "/manifest.json", false)
  xhr.send(null)
  manifest = JSON.parse(xhr.responseText)

  html_version = document.documentElement.getAttribute('data-app-version')
  if manifest.version isnt html_version
    location.reload(true)

  reg_res = /[\?&]q=([^&]+)/.exec(location.search)
  query = reg_res?[1] or "app"

  chrome.tabs.getCurrent (current_tab) ->
    chrome.windows.getAll {populate: true}, (windows) ->
      app_path = chrome.extension.getURL("app.html")
      for win in windows
        for tab in win.tabs
          if tab.id isnt current_tab.id and tab.url is app_path
            chrome.windows.update(win.id, {focused: true})
            chrome.tabs.update(tab.id, {selected: true})
            if query isnt "app"
              chrome.tabs.sendRequest(tab.id, {type: 'open', query: query})
            chrome.tabs.remove(current_tab.id)
            return
      history.pushState(null, null, "/app.html")
      $ () ->
        app.main()
        if query isnt "app"
          app.message.send("open", {query: query})
)()

app = {}

app.main = ->
  app.view.init()
  app.view.load_sidemenu()

  app.message.add_listener "open", (message) ->
    $container = $(".tab_container")
      .find("> [data-url=\"#{app.url.fix(message.url)}\"]")

    guess_result = app.url.guess_type(message.url)

    if $container.length is 1
      $container
        .closest(".tab")
          .tab "select", tab_id: $container.attr("data-tab_id")
    else if message.url is "config"
      app.view.open_config()
    else if message.url is "history"
      app.view.open_history()
    else if guess_result.type is "board"
      app.view.open_board(message.url)
    else if guess_result.type is "thread"
      app.view.open_thread(message.url)

`
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
              .animate({opacity: 0}, 'fast')
              .delay('fast')
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
`
