describe "app.Ninja", ->
  describe ".getCookie", ->
    it "全ての対応サイトの忍法帳Cookieを取得する", ->
      spyOn(chrome.cookies, "get")
      callback = jasmine.createSpy("callback")

      app.Ninja.getCookie(callback)

      expect(chrome.cookies.get.callCount).toBe(1)
      expect(chrome.cookies.get.mostRecentCall.args[0]).toEqual(
        url: "http://www.2ch.net/"
        name: "HAP"
      )

      expect(callback).not.toHaveBeenCalled()

      chrome.cookies.get.mostRecentCall.args[1].call(
        null,
        {
          domain: ".2ch.net"
          expirationDate: 1234567890
          hostOnly: false
          httpOnly: false
          name: "HAP"
          path: "/"
          secure: false
          session: false
          storeId: "0"
          value: "FOXdayo1234567890"
        }
      )

      expect(callback.callCount).toBe(1)
      expect(callback).toHaveBeenCalledWith([
        {site: app.Ninja._siteInfo["2ch"], value: "FOXdayo1234567890"}
      ])
      return
    return

  describe "deleteCookie", ->
    it "指定されたサイトの忍法用クッキーを削除する", ->
      spyOn(chrome.cookies, "remove")

      app.Ninja.deleteCookie("2ch")

      expect(chrome.cookies.remove.callCount).toBe(1)
      expect(chrome.cookies.remove.mostRecentCall.args[0]).toEqual(
        url: "http://www.2ch.net/"
        name: "HAP"
      )
      chrome.cookies.remove.mostRecentCall.args[1].call()
      return

    it "削除完了時にコールバックを実行する", ->
      spyOn(chrome.cookies, "remove")
      callback = jasmine.createSpy("callback")

      app.Ninja.deleteCookie("2ch", callback)

      expect(chrome.cookies.remove.callCount).toBe(1)
      expect(chrome.cookies.remove.mostRecentCall.args[0]).toEqual(
        url: "http://www.2ch.net/"
        name: "HAP"
      )
      expect(callback).not.toHaveBeenCalled()

      chrome.cookies.remove.mostRecentCall.args[1].call()
      expect(callback.callCount).toBe(1)
      return
    return
  return
