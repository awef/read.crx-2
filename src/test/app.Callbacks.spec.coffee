describe "app.Callbacks", ->
  it "コールバックが引数を編集しても他の部分に影響が出ない", ->
    callbacks = new app.Callbacks()
    cb0 = (obj) ->
      obj.test = 321
      return
    cb1 = jasmine.createSpy("cb1")

    callbacks.add(cb0)
    callbacks.add(cb1)
    callbacks.call({test: 123})

    expect(cb1).toHaveBeenCalledWith({test: 123})
    expect(callbacks._latestCallArg).toEqual([{test: 123}])
    return

  it "callを一回までしか受け付けない", ->
    callbacks = new app.Callbacks()
    cb0 = jasmine.createSpy("cb0")

    callbacks.add(cb0)
    callbacks.call(1)
    callbacks.call(2)
    callbacks.call(3)

    expect(cb0.callCount).toBe(1)
    expect(cb0).toHaveBeenCalledWith(1)
    return

  it "call後に新しいコールバックが追加された時、即座に実行される", ->
    callbacks = new app.Callbacks()
    cb0 = jasmine.createSpy("cb0")

    callbacks.call(1, 2, 3)
    callbacks.add(cb0)

    expect(cb0.callCount).toBe(1)
    expect(cb0).toHaveBeenCalledWith(1, 2, 3)
    return

  describe "::remove", ->
    it "コールバックを削除する", ->
      callbacks = new app.Callbacks(persistent: true)
      cb0 = jasmine.createSpy("cb0")
      cb1 = jasmine.createSpy("cb1")
      cb2 = jasmine.createSpy("cb2")

      callbacks.add(cb0)
      callbacks.add(cb1)
      callbacks.add(cb2)
      callbacks.call(1)
      callbacks.call(2)
      callbacks.remove(cb1)
      callbacks.call(3)

      expect(cb0.callCount).toBe(3)
      expect(cb1.callCount).toBe(2)
      expect(cb2.callCount).toBe(3)
      return

    it "コールバック実行中でもコールバックを削除出来る", ->
      callbacks = new app.Callbacks(persistent: true)
      cb0 = jasmine.createSpy("cb0")
      cb1 = jasmine.createSpy("cb1").andCallFake ->
        callbacks.remove(cb0)
        return
      cb2 = jasmine.createSpy("cb2")

      callbacks.add(cb0)
      callbacks.add(cb1)
      callbacks.add(cb2)
      callbacks.call(1)
      callbacks.call(2)
      callbacks.call(3)

      expect(cb0.callCount).toBe(1)
      expect(cb1.callCount).toBe(3)
      expect(cb2.callCount).toBe(3)
      return
    return

  describe "config.persistentがtrueの時", ->
    it "callを何回でも受け付ける", ->
      callbacks = new app.Callbacks(persistent: true)
      cb0 = jasmine.createSpy("cb0")

      callbacks.add(cb0)
      callbacks.call(1)
      callbacks.call(2)
      callbacks.call(3)

      expect(cb0.callCount).toBe(3)
      expect(cb0).toHaveBeenCalledWith(1)
      expect(cb0).toHaveBeenCalledWith(2)
      expect(cb0).toHaveBeenCalledWith(3)
      return

    it "call後に新しいコールバックが追加されても、次のcallまで何もしない", ->
      callbacks = new app.Callbacks(persistent: true)
      cb0 = jasmine.createSpy("cb0")

      callbacks.call(1, 2, 3)
      callbacks.add(cb0)

      expect(cb0).not.toHaveBeenCalled()

      callbacks.call(2, 3, 4)

      expect(cb0.callCount).toBe(1)
      expect(cb0).toHaveBeenCalledWith(2, 3, 4)
      return

    it "コールバック中でコールバックがaddされても無視する", ->
      callbacks = new app.Callbacks(persistent: true)
      cb0 = jasmine.createSpy("cb0")

      callbacks.add ->
        callbacks.add(cb0)
        return
      callbacks.call(1)

      expect(cb0).not.toHaveBeenCalled()

      callbacks.call(2)

      expect(cb0.callCount).toBe(1)
      expect(cb0).toHaveBeenCalledWith(2)
      return
    return
  return
