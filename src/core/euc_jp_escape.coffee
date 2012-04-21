app.module "euc_jp_escape", ["jquery"], ($, callback) ->
  get_name = do ->
    count = 0
    -> "euc_jp_escape_" + count++

  module = {}
  module.escape = (str) ->
    $.Deferred (d) ->
      name = get_name()

      $("<iframe>", {src: "/view/empty.html", name})
        .hide()
        .one "load", ->
          $(@).one "load", ->
            d.resolve(@contentWindow.location.search.replace(/^\?q=/, ""))
            return
          $("<form>", {
              action: "/view/empty.html"
              target: name
              "accept-charset": "euc-jp"
          })
            .hide()
            .append($("<input>", name: "q", value: str))
            .appendTo(document.body)
            .submit()
          return
        .appendTo(document.body)
      return
    .promise()

  $ ->
    callback(module)
    return
  return
