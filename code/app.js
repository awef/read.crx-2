var app;

app = {};

app.main = function() {
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

