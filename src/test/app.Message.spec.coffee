describe "app.Message", ->
  message = new app.Message()

  testIdSeed = 0
  testId = null

  beforeEach ->
    testIdSeed++
    testId = "__test#{testIdSeed}"
    return

  it "メッセージを送受信する", ->
    listener = jasmine.createSpy("listener")
    message.addListener(testId, listener)
    message.send(testId, "test")

    waitsFor ->
      listener.wasCalled

    runs ->
      expect(listener.callCount).toBe(1)
      expect(listener).toHaveBeenCalledWith("test")
      return
    return

  it "リスナがメッセージを編集しても、他のメッセージには影響無い", ->
    fake = (message) ->
      expect(message).toEqual(test: 123)
      message.test = 234
      return

    listener0 = jasmine.createSpy("listener0").andCallFake(fake)
    listener1 = jasmine.createSpy("listener1").andCallFake(fake)

    message.addListener(testId, listener0)
    message.addListener(testId, listener1)

    message.send(testId, test: 123)

    waitsFor ->
      listener0.wasCalled and listener1.wasCalled

    runs ->
      expect(listener0.callCount).toBe(1)
      expect(listener1.callCount).toBe(1)
      return
    return

  it "send後にメッセージが変更されても反映しない", ->
    listener0 = jasmine.createSpy("listener0")
    message.addListener(testId, listener0)

    msg = test: 0
    message.send(testId, msg)
    msg.test++

    waitsFor ->
      listener0.wasCalled

    runs ->
      expect(listener0).toHaveBeenCalledWith(test: 0)
      return
    return

  it "リスナ中からもリスナを削除できる", ->
    listener0 = jasmine.createSpy("listener0").andCallFake ->
      message.removeListener(testId, listener0)
      message.removeListener(testId, listener1)
      return
    listener1 = jasmine.createSpy("listener1")

    message.addListener(testId, listener0)
    message.addListener(testId, listener1)

    message.send(testId, "test")

    timeout = false
    setTimeout((-> timeout = true; return), 500)
    waitsFor ->
      timeout

    runs ->
      expect(listener0.callCount).toBe(1)
      expect(listener1.callCount).toBe(0)
      return
    return

  it "メッセージはparentやiframeにも伝播する", ->
    frameList = [
      "frame"
      "frame_1"
      "frame_1_1"
      "frame_2"
      "frame_2_1"
      "frame_2_2"
      "frame_2_2_1"
      "frame_2_3"
    ]
    frameList.sort()

    tmp = []
    message.addListener "message_test_pong", (message) ->
      tmp.push(message.source_id)
      return

    iframe = document.createElement("iframe")
    iframe.src = "message_test.html"
    document.querySelector("#jasmine-fixture").appendChild(iframe)

    timeout = false
    setTimeout((-> timeout = true; return), 500)
    waitsFor ->
      timeout

    runs ->
      tmp.sort()
      expect(tmp, frameList)
      return
    return
  return
