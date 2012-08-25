do ->
  jasmineEnv = jasmine.getEnv()

  htmlReporter = new jasmine.HtmlReporter()
  jasmineEnv.addReporter(htmlReporter)

  jasmineEnv.specFilter = (spec) ->
    htmlReporter.specFilter(spec)

  jasmineFixture = document.createElement("div")
  jasmineFixture.id = "jasmine-fixture"

  addEventListener "DOMContentLoaded", ->
    document.body.appendChild(jasmineFixture)
    return

  afterEach ->
    jasmineFixture.innerHTML = ""
    return

  QUnit.done ->
    jasmineEnv.execute()
    return
  return
