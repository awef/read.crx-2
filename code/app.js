var app;

app = {};

app.main = function() {
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

  $container = $('<div>');
  $('<div>')
    .text(text)
    .appendTo($container);
  $('<button>')
    .bind('click', function() {
        $(this)
          .parent()
            .slideUp('fast', function() {
              $(this).remove();
            });
      })
    .appendTo($container);
  $container
    .hide()
    .appendTo('#app_notice_container')
    .fadeIn();
};
