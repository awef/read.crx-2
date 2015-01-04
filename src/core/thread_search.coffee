app.module "thread_search", [], (callback) ->
  class ThreadSearch
    constructor: (@query) ->
      @offset = 0
      return

    read: ->
      $.ajax({
        url: "http://dig.2ch.net/?keywords=#{encodeURI(@query)}&maxResult=500"
        cache: false
        dataType: "text"
        timeout: 1000 * 30
      })
      .pipe(((responseText) => $.Deferred (d) =>
        # UA次第で別サイトのURLが返される場合が有るため対策
        responseText = responseText.replace(/http:\/\/bintan\.ula\.cc\/test\/read\.cgi\/([\w\.]+)\/(\w+)\/(\d+)\/\w*/g, "http://$1/test/read.cgi/$2/$3/")

        reg = /<span class="itashibori">([^<]+)<\/span>[\s\S]*?<a href="(http:\/\/\w+\.\w+\.\w+\/test\/read\.cgi\/\w*\/(\d+)\/)\w*">([^<]+?)\((\d+)\)<\/a>/g
        data = []
        while x = reg.exec(responseText)
          data.push
            url: x[2]
            created_at: +x[3] * 1000
            title: x[4]
            res_count: +x[5]
            board_url: null
            board_title: x[1]

        @offset += data.length
        d.resolve(data)
        return
      ), (=> $.Deferred (d) => d.reject(message: "通信エラー"); return))
      .promise()

  callback(ThreadSearch)
  return
