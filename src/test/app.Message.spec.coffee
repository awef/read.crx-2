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

  describe "ターゲットが指定された場合", ->
    it "指定されたWindowにのみメッセージを伝播させる", ->
      iframe0 = document.createElement("iframe")
      iframe0.src = "message_test.html?targetWindowTest"
      document.querySelector("#jasmine-fixture").appendChild(iframe0)

      iframe1 = document.createElement("iframe")
      iframe1.src = "message_test.html?targetWindowTest"
      document.querySelector("#jasmine-fixture").appendChild(iframe1)

      listener0 = jasmine.createSpy("listener")
      message.addListener("targetWindowTest-ready", listener0)

      listener1 = jasmine.createSpy("listener")
      message.addListener("targetWindowTest-pong", listener1)

      timeout = false

      waitsFor ->
        listener0.callCount is 2

      runs ->
        app.message.send("targetWindowTest-ping", "test", iframe0.contentWindow)

        setTimeout((-> timeout = true; return), 500)
        return

      waitsFor ->
        timeout

      runs ->
        expect(listener1.callCount).toBe(1)
        return
      return

    it "自Windowにさえイベントを伝播させない", ->
      iframe = document.createElement("iframe")
      iframe.src = "/view/empty.html"
      document.querySelector("#jasmine-fixture").appendChild(iframe)

      listener = jasmine.createSpy("listener")
      message.addListener(testId, listener)

      timeout = false

      waitsFor ->
        iframe.contentWindow?

      runs ->
        message.send(testId, "message", iframe.contentWindow)

        setTimeout((-> timeout = true; return), 500)
        return

      waitsFor ->
        timeout

      runs ->
        expect(listener).not.toHaveBeenCalled()
        return
      return
    return
  return
