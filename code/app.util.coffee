`/** @namespace */`
app.util = {}

app.util.date_to_string = (date) ->
  fn = (a) -> (if a < 10 then "0" else "") + a

  date.getFullYear() +
  "/" + fn(date.getMonth() + 1) +
  "/" + fn(date.getDate()) +
  " " + fn(date.getHours()) +
  ":" + fn(date.getMinutes())
