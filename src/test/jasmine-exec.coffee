do ->
  jasmineEnv = jasmine.getEnv()

  htmlReporter = new jasmine.HtmlReporter()
  jasmineEnv.addReporter(htmlReporter)

  jasmineEnv.specFilter = (spec) ->
    htmlReporter.specFilter(spec)

  QUnit.done ->
    jasmineEnv.execute()
    return

  return
