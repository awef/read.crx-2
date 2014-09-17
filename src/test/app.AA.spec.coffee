describe "app.AA", ->
  "use strict"
  
  data1 = null
  addData1 = null

  beforeEach ->
    date = +new Date()

    data1 = [
      {
        id: "4c0ba022-a5ac-4816-85c2-5e1e57f1bad6",
        title: "ブーン",
        date: date - 0,
        content: "⊂二二二（　＾ω＾）二⊃ ﾌﾞｰﾝ"
      },
      {
        id: "cd4f00ad-c47a-4a90-932b-f8960a841e85",
        title: "やる夫",
        date: date - 1,
        content: """
　 　　　 　　 　＿＿＿_
　　　　　　 ／ ＼　　／＼　 ｷﾘｯ
.　　　　　／　（ー） 　（ー）＼
　　　　／　　 ⌒（__人__）⌒ ＼
　　　　|　　 　　　|r┬-|　　　　|
　　　　 ＼　　　　 `ー'´　　 ／
　　　　ノ　　　　　　　　　　 　＼
　 ／´　　　　　　　　　　　　 　　ヽ
　|　　　　ｌ　　　　　　　　　　　　　　＼
　ヽ　　　 -一''''''"~~｀`'ー--､　　　-一'''''''ー-､.
　　ヽ ＿＿＿＿(⌒)(⌒)⌒)　)　　(⌒＿(⌒)⌒)⌒))


　 　　　　 　　　＿＿＿_
　　　　　　　 ／_ノ 　ヽ､_＼
　ﾐ　ﾐ　ﾐ　　oﾟ(（●）) (（●）)ﾟo　　　　　　ﾐ　ﾐ　ﾐ　　　だっておｗｗｗｗｗｗｗｗｗｗ
/⌒)⌒)⌒. ::::::⌒（__人__）⌒:::＼　　　/⌒)⌒)⌒)
|　/　/　/　　　　　|r┬-|　　　　|　(⌒)/　/ / /／
|　:::::::::::(⌒)　　　　|　|　 |　　 ／ 　ゝ　　:::::::::::/
|　　　　　ノ　　 　　|　|　 |　 　＼　　/　　）　　/
ヽ　　　　/　　　　　`ー'´ 　 　 　ヽ /　　　　／
　|　　　　|　　 l||l　从人 l||l 　　　　 l||l 从人 l||l
　ヽ　　　 -一''''''"~~｀`'ー--､　　　-一'''''''ー-､
　　ヽ ＿＿＿＿(⌒)(⌒)⌒)　)　　(⌒＿(⌒)⌒)⌒))"""
      }
      {
        id: "9e0d6b65-47eb-40c5-b114-1cdbffbe56c3",
        title: "真顔",
        date: date - 2,
        content: """
　　　　　　　／￣￣￣￣＼
　　　　　　/;;::　　　　　　　::;ヽ
　　　　　　|;;:: ｨ●ｧ　　ｨ●ｧ::;;|
　　　　　　|;;::　　　　　　　　::;;|
　　　　　　|;;:: 　　c{　っ　　::;;|
　　　　　　 |;;::　　＿＿　　::;;;|
　　　　　　 ヽ;;::　　ー　　::;;／
　　　　　　　　＼;;::　　::;;／
　　　　　　　　　 |;;::　 ::;;|
　　　　　　　　　 |;;::　 ::;;|
　　　／￣￣￣　　　　 ￣￣￣＼
　　　|;;::　　　　　　　　　 　　　　 ::;;|
　　　|;;::　　　　　　　　　　　　　　::;;|"""
      }
    ]
    
    addData1 = ->
      $.Deferred (d) ->
        tmp = []

        fn = (item) ->
          tmp.push(app.AA.add(item.id, item.title, item.content, item.date))
          return

        fn(data1[1])
        fn(data1[0])
        fn(data1[2])

        $.when.apply(null, tmp).done(-> d.resolve(); return)
        return

    return

    
  it "AAを格納/取得できる", ->
    for item in data1
      promise = app.AA.add(item.id, item.title, item.content, item.date)

      waitsFor ->
        promise.state() is "resolved"

      runs ->
        promise = app.AA.get(item.id)
        return

      waitsFor ->
        promise.state() is "resolved"

      runs ->
        promise.done (data) ->
          expect(data.id).toEqual(item.id)
          expect(data.title).toEqual(item.title)
          expect(data.content).toEqual(item.content)
          #expect(data.date).toEqual(item.date)
          return
        return

    return


  it "取得したAAのリストは更新日時が新しい順にソートされている", ->
    promise = addData1().promise()

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise = app.AA.getList(undefined, undefined)
      return

    waitsFor ->
      promise.state() is "resolved"

    runs ->
      promise.done (data) ->
        ###i = 0
        for item in data
          expect(item.id).toEqual(data1[i].id)
          expect(item.title).toEqual(data1[i].title)
          expect(item.date).toEqual(data1[i].date)
          i++
        expect(i, 3)
        ###
        i = 0
        while i < 3
          expect(data[i].id).toEqual(data1[i].id)
          expect(data[i].title).toEqual(data1[i].title)
          expect(data[i].date).toEqual(data1[i].date)
          i++
        expect(i).toEqual(3)
        return
      return
    return

  it "期待されない引数が渡された時はrejectされている", ->
    date = +new Date()
    expect(app.AA.add(undefined, "title", "content", date).state()).toBe("rejected")
    expect(app.AA.add("202cbbd6-3e07-40be-8266-1af66d132409", undefined, "content", date).state()).toBe("rejected")
    expect(app.AA.add("1383c94e-caf3-47a3-a3fb-a5b07207e133", "title", undefined, date).state()).toBe("rejected")
    expect(app.AA.add("d4100964-3b64-4a4b-9f82-bef63248f19b", "title", undefined, undefined).state()).toBe("rejected")
    expect(app.AA.add("d4100964-3b64-4a4b-9f82-bef63248f19b", "title", undefined, String(date)).state()).toBe("rejected")
    return

  describe "::remove", ->
    it "与えられたIDのAAを削除する", ->
      addPromise = addData1().promise()
      removePromise = null
      getPromise = null
  
      waitsFor ->
        addPromise.state() is "resolved"
  
      runs ->
        removePromise = app.AA.remove(data1[2].id)
        return
  
      waitsFor ->
          removePromise.state() is "resolved"
  
      runs ->
          getPromise = app.AA.get(data1[2].id)
          return

      waitsFor ->
          getPromise.state() is "resolved"

      runs ->
        getPromise.done (data) ->
          expect(data).toEqual(null)
          return
        return
      return

    it "期待されない引数が与えられた時はrejectされる", ->
      expect(app.AA.remove(undefined).state()).toBe("rejected")
      expect(app.AA.remove(0xbeafbeaf).state()).toBe("rejected")
      expect(app.AA.remove(null).state()).toBe("rejected")
      return


