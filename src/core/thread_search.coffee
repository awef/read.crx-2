app.module "thread_search", [], (callback) ->
  class ThreadSearch
    constructor: (@_query) ->
      return

    read: ->
      $.ajax({
        url: "http://search.2ch.net/search.json?q=#{encodeURIComponent(@_query)}&size=100"
        cache: false
        dataType: "text"
        timeout: 1000 * 30
      })
        .pipe(((responseText) => $.Deferred (d) =>
          try
            result = JSON.parse(responseText)
          catch
            d.reject(message: "通信エラー（JSONパースエラー）")
            return

          data = []

          result.results.forEach (entry) =>
            thread =
              url: "http://#{entry.source.server}.#{entry.source.host}/test/read.cgi/#{entry.source.board}/#{entry.source.thread_id}/"
              created_at: Date.parse(entry.source.date)
              title: entry.source.title
              res_count: entry.source.comment_count
              board_url: "http://#{entry.source.server}.#{entry.source.host}/#{entry.source.board}/"
              board_title: ""

            app.BoardTitleSolver.ask(url: thread.board_url, offline: true).done (result) =>
              thread.board_title = result
              return

            data.push thread
            return

          d.resolve(data)
          return
        ), (=> $.Deferred (d) => d.reject(message: "通信エラー"); return))
        .promise()

  callback(ThreadSearch)
  return
