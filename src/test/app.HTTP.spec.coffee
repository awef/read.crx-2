describe "app.HTTP.Request", ->
  describe "@parseHTTPHeader", ->
    it "HTTPヘッダをパースする", ->
      header = """
        Date: Fri, 28 Sep 2012 12:01:34 GMT
        Content-Encoding: gzip
        Connection: keep-alive
        X-Frame-Options: deny
        X-Hoge: test 
          test
      """
      expect(app.HTTP.Request.parseHTTPHeader(header)).toEqual(
        "Date": "Fri, 28 Sep 2012 12:01:34 GMT"
        "Content-Encoding": "gzip"
        "Connection": "keep-alive"
        "X-Frame-Options": "deny"
        "X-Hoge": "test   test"
      )
      return
    return
  return
