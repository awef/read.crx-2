app.module "thread_search", ["euc_jp_escape"], (euc_jp_escape, callback) ->
  class ThreadSearch
    constructor: (@_query) ->
      @_offset = 0
      @_escape = euc_jp_escape.escape(@_query)
      return
    read: ->
      @_escape
        .pipe (query) =>
          url = "http://find.2ch.net/index.php?"
          url += [
            "BBS=2ch"
            "TYPE=TITLE"
            "SORT=CREATED"
            "STR=#{query}"
            "OFFSET=#{@_offset}"
            "_from=read.crx-2"
          ].join("&")


          $.ajax({
            url
            cache: false
            dataType: "text"
            mimeType: "text/html; charset=EUC-JP"
            timeout: 1000 * 30
          })
        .pipe(((responseText) => $.Deferred (d) =>
          reg = ///
            ^<dt>
              <a\u0020href="(http://\w+\.\w+\.\w+/test/read\.cgi/\w*/(\d+)/)\d+\-\d+">
              ([^<]+)
              </a>\u0020\((\d+)\)\u0020\-\u0020<font\u0020size=-1>
              <a\u0020href=(http://\w+\.\w+\.\w+/\w+/)>([^<]+)
          ///gim

          data = []
          while x = reg.exec(responseText)
            data.push
              url: x[1]
              created_at: +x[2] * 1000
              title: app.util.decode_char_reference(x[3])
              res_count: +x[4]
              board_url: x[5]
              board_title: app.util.decode_char_reference(x[6])
          @_offset += data.length
          d.resolve(data)
          return
        ), (=> $.Deferred (d) => d.reject(message: "通信エラー"); return))
        .promise()

  callback(ThreadSearch)
  return
