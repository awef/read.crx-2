var app;

app = {};

app.main = function() {
};

app.deep_copy = function(data) {
  return JSON.parse(JSON.stringify(data));
};

