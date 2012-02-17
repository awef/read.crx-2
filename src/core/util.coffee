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

  anchor_reg = /(?:&gt;|＞){1,2}[\d\uff10-\uff19]+(?:[\-ー][\d\uff10-\uff19]+)?(?:\s*,\s*[\d\uff10-\uff19]+(?:[\-ー][\d\uff10-\uff19]+)?)*/g
  while anchor_res = anchor_reg.exec(str)
    anchor_str = anchor_res[0]
      .replace(/ー/g, "-")
      .replace /[\uff10-\uff19]/g, ($0) ->
        String.fromCharCode($0.charCodeAt(0) - 65248)

    anchor =
      segments: []
      target: 0

    segment_reg = /(\d+)(?:-(\d+))?/g
    while segment_res = segment_reg.exec(anchor_str)
      if segment_res[2]
        continue if (+segment_res[2]) < (+segment_res[1])
        segrange_start = +segment_res[1]
        segrange_end = +segment_res[2]
      else
        segrange_start = segrange_end = +segment_res[1]

      anchor.target += segrange_end - segrange_start + 1
      anchor.segments.push([segrange_start, segrange_end])

    if anchor.target > 0
      total.target += anchor.target
      total.data.push(anchor)

  total

#2chの鯖移転検出関数
#移転を検出した場合は移転先のURLをresolveに載せる
#検出出来なかった場合はrejectする
#htmlを渡す事で通信をスキップする事が出来る
app.util.ch_server_move_detect = (old_board_url, html) ->
  $.Deferred (deferred) ->
    if typeof html is "string"
      deferred.resolve(html)
    else
      deferred.reject()

  #htmlが渡されなかった場合は通信する
  .pipe null, ->
    $.Deferred (deferred) ->
      $.ajax
        url: old_board_url
        cache: false
        dataType: "text"
        timeout: 1000 * 30
        mimeType: "text/html; charset=Shift_JIS"
        complete: ($xhr) ->
          if $xhr.status is 200
            deferred.resolve($xhr.responseText)
          else
            deferred.reject()

  #htmlから移転を判定
  .pipe (html) ->
    $.Deferred (deferred) ->
      res = ///location\.href="(http://\w+\.2ch\.net/\w*/)"///.exec(html)

      if res and res[1] isnt old_board_url
        deferred.resolve(res[1])
      else
        deferred.reject()

  #移転を検出した場合は移転検出メッセージを送出
  .done (new_board_url) ->
    app.message.send("detected_ch_server_move",
      {before: old_board_url, after: new_board_url})

  .promise()

#文字参照をデコード
do ->
  span = document.createElement("span")

  app.util.decode_char_reference = (str) ->
    str.replace /\&(?:#(\d+)|#x([\dA-Fa-f]+)|([\da-zA-Z]+));/g, ($0, $1, $2, $3) ->
      #数値文字参照 - 10進数
      if $1?
        String.fromCharCode($1)
      #数値文字参照 - 16進数
      else if $2?
        String.fromCharCode(parseInt($2, 16))
      #文字実体参照
      else if $3?
        span.innerHTML = $0
        span.textContent
      else
        $0

#マウスクリックのイベントオブジェクトから、リンク先をどう開くべきかの情報を導く
app.util.get_how_to_open = (original_e) ->
  e = {which, shiftKey, ctrlKey} = original_e
  e.ctrlKey or= original_e.metaKey
  def = {new_tab: false, new_window: false, background: false}
  if e.type is "click"
    if e.which is 1 and not e.shiftKey and not e.ctrlKey
      {new_tab: false, new_window: false, background: false}
    else if e.which is 1 and e.shiftKey and not e.ctrlKey
      {new_tab: false, new_window: true, background: false}
    else if e.which is 1 and not e.shiftKey and e.ctrlKey
      {new_tab: true, new_window: false, background: true}
    else if e.which is 1 and e.shiftKey and e.ctrlKey
      {new_tab: true, new_window: false, background: false}
    else if e.which is 2 and not e.shiftKey and not e.ctrlKey
      {new_tab: true, new_window: false, background: true}
    else if e.which is 2 and e.shiftKey and not e.ctrlKey
      {new_tab: true, new_window: false, background: false}
    else if e.which is 2 and not e.shiftKey and e.ctrlKey
      {new_tab: true, new_window: false, background: true}
    else if e.which is 2 and e.shiftKey and e.ctrlKey
      {new_tab: true, new_window: false, background: false}
    else
      def
  else
    def

app.util.levenshtein_distance = (a, b) ->
  table = [[0...b.length + 1]]
  for ac in [1...a.length + 1]
    table[ac] = [ac]

  for ac in [1...a.length + 1]
    for bc in [1...b.length + 1]
      table[ac][bc] = Math.min(
        table[ac - 1][bc] + 1
        table[ac][bc - 1] + 1
        table[ac - 1][bc - 1] + if a[ac - 1] is b[bc - 1] then 0 else 1
      )

  table[a.length][b.length]

app.util.search_next_thread = (thread_url, thread_title) ->
  $.Deferred (d) ->
    thread_url = app.url.fix(thread_url)
    board_url = app.url.thread_to_board(thread_url)
    app.board.get board_url, (res) ->
      if res.data?
        tmp = res.data
        tmp = tmp.filter (thread) ->
          thread.url isnt thread_url
        tmp = tmp.map (thread) ->
          {
            score: app.util.levenshtein_distance(thread_title, thread.title)
            title: thread.title
            url: thread.url
          }
        tmp.sort (a, b) ->
          a.score - b.score
        d.resolve(tmp[0...5])
      else
        d.reject()
      return
    return
  .promise()

#検索用に全角/半角や大文字/小文字を揃える
app.util.normalize = (str) ->
  str
    #全角英数を半角英数に変換
    .replace(
      ///[
        \uff10-\uff19 #０-９
        \uff21-\uff3a #Ａ-Ｚ
        \uff41-\uff5a #ａ-ｚ
      ]///g
      ($0) -> String.fromCharCode($0.charCodeAt(0) - 65248)
    )
    #カタカナをひらがなに変換
    .replace(
      ///[
        \u30a2-\u30f3 #ア-ン
      ]///g
      ($0) -> String.fromCharCode($0.charCodeAt(0) - 96)
    )
    #半角カタカナを平仮名に変換
    .replace(
      ///[
        \uff66-\uff6f #ｦ-ｯ
        #\uff70は半カナではない
        \uff71-\uff9d #ｱ-ﾝ
      ]///g
      ($0) ->
        String.fromCharCode({
          0xff66: 0x3092
          0xff67: 0x3041
          0xff68: 0x3043
          0xff69: 0x3045
          0xff6a: 0x3047
          0xff6b: 0x3049
          0xff6c: 0x3083
          0xff6d: 0x3085
          0xff6e: 0x3087
          0xff6f: 0x3063
          0xff71: 0x3042
          0xff72: 0x3044
          0xff73: 0x3046
          0xff74: 0x3048
          0xff75: 0x304a
          0xff76: 0x304b
          0xff77: 0x304d
          0xff78: 0x304f
          0xff79: 0x3051
          0xff7a: 0x3053
          0xff7b: 0x3055
          0xff7c: 0x3057
          0xff7d: 0x3059
          0xff7e: 0x305b
          0xff7f: 0x305d
          0xff80: 0x305f
          0xff81: 0x3061
          0xff82: 0x3064
          0xff83: 0x3066
          0xff84: 0x3068
          0xff85: 0x306a
          0xff86: 0x306b
          0xff87: 0x306c
          0xff88: 0x306d
          0xff89: 0x306e
          0xff8a: 0x306f
          0xff8b: 0x3072
          0xff8c: 0x3075
          0xff8d: 0x3078
          0xff8e: 0x307b
          0xff8f: 0x307e
          0xff90: 0x307f
          0xff91: 0x3080
          0xff92: 0x3081
          0xff93: 0x3082
          0xff94: 0x3084
          0xff95: 0x3086
          0xff96: 0x3088
          0xff97: 0x3089
          0xff98: 0x308a
          0xff99: 0x308b
          0xff9a: 0x308c
          0xff9b: 0x308d
          0xff9c: 0x308f
          0xff9d: 0x3093
        }[$0.charCodeAt(0)])
    )
    #全角スペース/半角スペースを削除
    .replace(/[\u0020\u3000]/g, "")
    #大文字を小文字に変換
    .toLowerCase()
