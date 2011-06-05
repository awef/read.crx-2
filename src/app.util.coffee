app.util = {}

app.util.date_to_string = (date) ->
  fn = (a) -> (if a < 10 then "0" else "") + a

  date.getFullYear() +
  "/" + fn(date.getMonth() + 1) +
  "/" + fn(date.getDate()) +
  " " + fn(date.getHours()) +
  ":" + fn(date.getMinutes())

# #app.util.calc_heat
# スレの勢いを算出する関数  
# 引数は現在の時刻、スレが立てられた時刻、スレのレス数  
# 文字列を返す
app.util.calc_heat = (now, thread_created, res_count) ->
  (res_count / ((now - thread_created) / (24 * 60 * 60 * 1000))).toFixed(1)

# #app.util.anchor_parse
# 文字列中の全てのアンカーの情報をパースする
app.util.parse_anchor = (str) ->
  total =
    data: []
    target: 0

  anchor_reg = /(?:>|&gt;|＞){1,2}[\d０-９]+(?:[\-ー][\d０-９]+)?(?:\s*,\s*[\d０-９]+(?:[\-ー][\d０-９]+)?)*/g
  while anchor_res = anchor_reg.exec(str)
    anchor_str = anchor_res[0]
      .replace(/ー/g, "-")
      .replace /[０-９]/g, ($0) ->
        String.fromCharCode($0.charCodeAt(0) - 65248)

    anchor =
      segments: []
      target: 0

    segment_reg = /(\d+)(?:-(\d+))?/g
    while segment_res = segment_reg.exec(anchor_str)
      if segment_res[2]
        segrange_start = +segment_res[1]
        segrange_end = +segment_res[2]
      else
        segrange_start = segrange_end = +segment_res[1]

      anchor.target += segrange_end - segrange_start + 1
      anchor.segments.push([segrange_start, segrange_end])

    total.target += anchor.target
    total.data.push(anchor)

  total
