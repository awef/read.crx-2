`/** @namespace */`
app.util = {}

app.util.date_to_string = (date) ->
  fn = (a) -> (if a < 10 then "0" else "") + a

  date.getFullYear() +
  "/" + fn(date.getMonth() + 1) +
  "/" + fn(date.getDate()) +
  " " + fn(date.getHours()) +
  ":" + fn(date.getMinutes())

`/**
* @param now {number}
* @param thread_created {number}
* @param res_count {number}
*/`
app.util.calc_heat = (now, thread_created, res_count) ->
  (res_count / ((now - thread_created) / (24 * 60 * 60 * 1000))).toFixed(1)
