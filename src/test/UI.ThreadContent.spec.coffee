describe "UI.ThreadContent", ->
  example = null

  beforeEach ->
    example = {}

    example.a = {}
    example.a.url = "http://jbbs.livedoor.jp/bbs/read.cgi/computer/42710/0123456789/"
    example.a.data1 =
      name: "名無しさん"
      mail: "sage"
      other: "2010/05/14(木) 15:41:14 ID:iTGL5FKU"
      message: "test"

    example.a.dom1 = (
      $("<div>").append(
        $("<article>", class: "one", "data-id": "ID:iTGL5FKU").append(
          $("<header>").append(
            $("<span>", class: "num", text: "1")
            " "
            $("<span>", class: "name", text: "名無しさん")
            " ["
            $("<span>", class: "mail", text: "sage")
            "] "
            $("<span>", class: "other").append(
              document.createTextNode("2010/05/14(木) 15:41:14 ")
              $("<span>", class: "id", text: "ID:iTGL5FKU(1)")
            )
          )
          $("<div>", class: "message", text: "test")
        )
      )
    )[0]

    example.a.data2 =
      name: "774"
      mail: ""
      other: "2010/05/14(木) 15:51:14 ID:iTGL5FKU"
      message: "test<br>&gt;&gt;1"

    example.a.dom2 = (
      $("<div>").append(
        $("<article>", class: "one", "data-id": "ID:iTGL5FKU").append(
          $("<header>").append(
            $("<span>", class: "num", text: "1")
            " "
            $("<span>", class: "name", text: "名無しさん")
            " ["
            $("<span>", class: "mail", text: "sage")
            "] "
            $("<span>", class: "other").append(
              document.createTextNode("2010/05/14(木) 15:41:14 ")
              $("<span>", class: "id link", text: "ID:iTGL5FKU(2)")
              " "
              $("<span>", class: "rep link", text: "返信 (1)")
            )
          )
          $("<div>", class: "message", text: "test")
        )
        $("<article>", class: "one", "data-id": "ID:iTGL5FKU").append(
          $("<header>").append(
            $("<span>", class: "num", text: "2")
            " "
            $("<span>", class: "name name_anchor", text: "774")
            " ["
            $("<span>", class: "mail", text: "")
            "] "
            $("<span>", class: "other").append(
              document.createTextNode("2010/05/14(木) 15:51:14 ")
              $("<span>", class: "id link", text: "ID:iTGL5FKU(2)")
            )
          )
          $("<div>", class: "message", html: """test<br><a href="javascript:undefined;" class="anchor">&gt;&gt;1</a>""")
        )
      )
    )[0]
    return

  hogehoge = (idIndex = {"ID:iTGL5FKU": [1]}, repIndex = {}) ->
    div = document.createElement("div")
    threadContent = new UI.ThreadContent(example.a.url, div)
    threadContent.addItem(example.a.data1)

    expect(div.innerHTML).toBe(example.a.dom1.innerHTML)
    expect(threadContent.idIndex).toEqual(idIndex)
    expect(threadContent.repIndex).toEqual(repIndex)
    return

  describe "::addItem", ->
    it "レスのデータからDOMを構築する", ->
      div = document.createElement("div")
      threadContent = new UI.ThreadContent(example.a.url, div)
      threadContent.addItem(example.a.data1)

      expect(div.innerHTML).toBe(example.a.dom1.innerHTML)

      threadContent.addItem(example.a.data2)

      expect(div.innerHTML).toBe(example.a.dom2.innerHTML)
      return

    it "idIndexを更新する", ->
      div = document.createElement("div")
      threadContent = new UI.ThreadContent(example.a.url, div)
      threadContent.addItem(example.a.data1)

      expect(threadContent.idIndex).toEqual("ID:iTGL5FKU": [1])

      threadContent.addItem(example.a.data2)

      expect(threadContent.idIndex).toEqual("ID:iTGL5FKU": [1, 2])
      return

    it "repIndexを更新する", ->
      div = document.createElement("div")
      threadContent = new UI.ThreadContent(example.a.url, div)
      threadContent.addItem(example.a.data1)

      expect(threadContent.repIndex).toEqual({})

      threadContent.addItem(example.a.data2)

      expect(threadContent.repIndex).toEqual(1: [2])
      return

    it "元データにタグが入っていても無視する", ->
      #基本的にタグは除去
      #ただし名前欄はニダーのAAが入る事が有るのでエスケープに
      example.a.data1.name = "<script>名無しさん</script>"
      example.a.dom1.querySelector(".name").innerHTML = "&lt;script&gt;名無しさん&lt;/script&gt;"
      example.a.data1.mail = "<script>alert();</script>sage"
      example.a.dom1.querySelector(".mail").innerHTML = "alert();sage"
      example.a.data1.other = "2010/05/14(木) 15:41:14 <script>ID:iTGL5FKU</script>"
      example.a.data1.message = "test<script>alert();</script>"
      example.a.dom1.querySelector(".message").innerHTML = "testalert();"
      example.a.data1.message = """
        test<div>test</div>test<a href="test">test</a>test<script>alert();</script>test<style>test</style>test<test></test></test/><test
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        testtesttesttesttestalert();testtesttest
      """

      hogehoge()

      example.a.data1.other = "2010/05/14(木) 15:41:14 ID:i<p>TGL</p>5FKU"
      example.a.dom1.querySelector(".other").innerHTML = """
        2010/05/14(木) 15:41:14 <span class="id">ID:iTGL5FKU(1)</span>
      """

      hogehoge()
      return

    it "IDに使用されない文字列が含まれていた場合、それ以降をIDとして認識しない", ->
      example.a.data1.other = "2010/05/14(木) 15:41:14 ID:iTG\"L5FKU"
      example.a.dom1.querySelector("article").setAttribute("data-id", "ID:iTG")
      example.a.dom1.querySelector(".other").innerHTML = """
        2010/05/14(木) 15:41:14 <span class="id">ID:iTG(1)</span>"L5FKU
      """

      hogehoge("ID:iTG": [1])
      return

    it "名前欄の</b><b>はspan.obに置換する", ->
      example.a.data1.name = "******** </b>◆ABCDEFGH1iJ2 <b>"
      example.a.dom1.querySelector(".name").innerHTML = """
        ******** <span class="ob">◆ABCDEFGH1iJ2 </span>
      """

      hogehoge()

      example.a.data1.name = "</b>名無しの報告 <b></b>(北海道)<b>"
      example.a.dom1.querySelector(".name").innerHTML = """
        <span class="ob">名無しの報告 </span><span class="ob">(北海道)</span>
      """

      hogehoge()
      return

    it ".nameがレス番/アンカーとして解釈出来る場合、.name_anchorを付与する", ->
      example.a.data1.name = "123"
      example.a.dom1.querySelector(".name").textContent = "123"
      example.a.dom1.querySelector(".name").classList.add("name_anchor")

      hogehoge()

      example.a.data1.name = "&gt;&gt;123"
      example.a.dom1.querySelector(".name").textContent = ">>123"
      example.a.dom1.querySelector(".name").classList.add("name_anchor")

      hogehoge()

      example.a.data1.name = "＞＞１２３ー１２５"
      example.a.dom1.querySelector(".name").textContent = "＞＞１２３ー１２５"
      example.a.dom1.querySelector(".name").classList.add("name_anchor")

      hogehoge()

      # 前後の空白も許容する
      example.a.data1.name = "   123　 "
      example.a.dom1.querySelector(".name").textContent = "   123　 "
      example.a.dom1.querySelector(".name").classList.add("name_anchor")

      hogehoge()

      # 全角文字列も許容する
      example.a.data1.name = "1２３"
      example.a.dom1.querySelector(".name").textContent = "1２３"
      example.a.dom1.querySelector(".name").classList.add("name_anchor")

      hogehoge()
      return

    it "beのプロフィールページにリンクする", ->
      example.a.data1.other += " BE:123-ABC(10000)"
      example.a.dom1.querySelector(".other").insertAdjacentHTML(
        "beforeend",
        """ <a class="beid" href="http://be.2ch.net/test/p.php?i=123" target="_blank">BE:123-ABC(10000)</a>"""
      )

      hogehoge()

      example.a.data1.other = "BE:123-ABC(10000)"
      example.a.dom1.querySelector("article").className = ""
      example.a.dom1.querySelector("article").removeAttribute("data-id")
      example.a.dom1.querySelector(".other").innerHTML =
        """<a class="beid" href="http://be.2ch.net/test/p.php?i=123" target="_blank">BE:123-ABC(10000)</a>"""

      hogehoge({}, {})
      return

    it "名前欄のフォントタグを容認する", ->
      example.a.data1.name = "<font color=#FF0000>awef★</font>"
      example.a.dom1.querySelector(".name").innerHTML = "<font color=#FF0000>awef★</font>"

      hogehoge()
      return

    it "本文中のbr, hr, bタグを容認する", ->
      example.a.data1.message = """
        test<hr><br><b>test</b><b></b><br><br>test<BR>t<hr><hr><b></b>est
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        test<hr><br><b>test</b><b></b><br><br>test<BR>t<hr><hr><b></b>est
      """

      hogehoge()
      return

    it "本文中のURLをA要素に置換する", ->
      example.a.data1.message = "test http://goo.gl/e test"
      example.a.dom1.querySelector(".message").innerHTML = """
        test <a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a> test
      """

      hogehoge()
      return

    it "URL中に文字参照が入っていても許容する", ->
      example.a.data1.message = "test http://goo.gl/e?1&amp;1 test"
      example.a.dom1.querySelector(".message").innerHTML = """
        test <a href="http://goo.gl/e?1&amp;1" target="_blank">http://goo.gl/e?1&amp;1</a> test
      """

      hogehoge()
      return

    it "URLは空白文字以外と隣接していても認識する", ->
      example.a.data1.message = "テストhttp://goo.gl/eテスト"
      example.a.dom1.querySelector(".message").innerHTML = """
        テスト<a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a>テスト
      """

      hogehoge()
      return

    it "アンカー表記をリンクに置換する", ->
      example.a.data1.message = "&gt;&gt;2 &gt;3 ＞４"
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="javascript:undefined;" class="anchor">&gt;&gt;2</a> 
        <a href="javascript:undefined;" class="anchor">&gt;3</a> 
        <a href="javascript:undefined;" class="anchor">＞４</a>
      """.replace(/\n/g, "")

      hogehoge(null, {2: [1], 3: [1], 4: [1]})
      return

    it "アンカー表記は空白文字以外と隣接していても認識する", ->
      example.a.data1.message = "te&gt;&gt;2st te&gt;3st te＞４st"
      example.a.dom1.querySelector(".message").innerHTML = """
        te<a href="javascript:undefined;" class="anchor">&gt;&gt;2</a>st 
        te<a href="javascript:undefined;" class="anchor">&gt;3</a>st 
        te<a href="javascript:undefined;" class="anchor">＞４</a>st
      """.replace(/\n/g, "")

      hogehoge(null, {2: [1], 3: [1], 4: [1]})
      return

    it "アンカーとURLが隣接している状況も適切に認識する", ->
      example.a.data1.message = """
        http://goo.gl/e&gt;2 &gt;3http://goo.gl/e &gt;4http://goo.gl/e&gt;5
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a><a href="javascript:undefined;" class="anchor">&gt;2</a> 
        <a href="javascript:undefined;" class="anchor">&gt;3</a><a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a> 
        <a href="javascript:undefined;" class="anchor">&gt;4</a><a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a><a href="javascript:undefined;" class="anchor">&gt;5</a>
      """.replace(/\n/g, "")

      hogehoge(null, {2: [1], 3: [1], 4: [1], 5: [1]})
      return

    it "本文中のID表記をIDリンクに置換する", ->
      example.a.data1.message = "test ID:iTGL5FKU test ID:iTGL5FK! test"
      example.a.dom1.querySelector(".message").innerHTML = """
        test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FK!</a> test
      """

      hogehoge()
      return

    it "空白文字以外と隣接しているID表記も認識する", ->
      example.a.data1.message = "テストID:iTGL5FKUテスト"
      example.a.dom1.querySelector(".message").innerHTML = 'テスト<a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a>テスト'

      hogehoge()
      return

    it "連続したID表記も認識する", ->
      example.a.data1.message = "test ID:iTGL5FKUiD:iTGL5FKUId:iTGL5FKUid:iTGL5FKU test"
      example.a.dom1.querySelector(".message").innerHTML = """
        test <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">iD:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">Id:iTGL5FKU</a><a href="javascript:undefined;" class="anchor_id">id:iTGL5FKU</a> test
      """

      hogehoge()
      return

    it "IDとURLが隣接していても認識する", ->
      example.a.data1.message = """
        http://goo.gl/eID:iTGL5FKU 
        ID:iTGL5FKUhttp://goo.gl/e 
        http://goo.gl/eID:iTGL5FKUhttp://goo.gl/e 
        ID:iTGL5FKUhttp://goo.gl/eID:iTGL5FKU
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> 
        <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a> 
        <a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a> 
        <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="http://goo.gl/e" target="_blank">http://goo.gl/e</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a>
      """

      hogehoge()
      return

    it "連続したアンカーも認識する", ->
      example.a.data1.message = """
        &gt;&gt;2-4, 10&gt;2＞２
      """.replace(/\n/g, "")
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="javascript:undefined;" class="anchor">&gt;&gt;2-4, 10</a>
        <a href="javascript:undefined;" class="anchor">&gt;2</a>
        <a href="javascript:undefined;" class="anchor">＞２</a>
      """.replace(/\n/g, "")

      hogehoge(null, {2: [1], 3: [1], 4: [1], 10: [1]})
      return

    it "アンカーとIDが隣接していた場合も認識する", ->
      example.a.data1.message = """
        &gt;2ID:iTGL5FKU 
        ID:iTGL5FKU&gt;3 
        &gt;4ID:iTGL5FKU&gt;5
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="javascript:undefined;" class="anchor">&gt;2</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a> 
        <a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor">&gt;3</a> 
        <a href="javascript:undefined;" class="anchor">&gt;4</a><a href="javascript:undefined;" class="anchor_id">ID:iTGL5FKU</a><a href="javascript:undefined;" class="anchor">&gt;5</a>
      """

      hogehoge(null, {2: [1], 3: [1], 4: [1], 5: [1]})
      return

    it "本文中にAAが含まれている場合は.aaを付与する", ->
      example.a.data1.message = """
        　 ∧＿∧<br>
        　（　´∀｀）<br>
        　（　　 　 ）<br>
        　│ │ │<br>
        　（＿_）＿）<br>
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        　 ∧＿∧<br>
        　（　´∀｀）<br>
        　（　　 　 ）<br>
        　│ │ │<br>
        　（＿_）＿）<br>
      """
      example.a.dom1.querySelector("article").className = "aa one"

      hogehoge()
      return

    it "2chのスレッドではレス冒頭のsssp://リンクを埋め込み表示する", ->
      example.a.url = "http://__dummy.2ch.net/test/read.cgi/__dummy/1234567890/"
      example.a.data1.message = """
        sssp://img.2ch.net/ico/u_utyuu.gif<br>
        test
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        <img class="beicon" src="/img/dummy_1x1.png" data-src="http://img.2ch.net/ico/u_utyuu.gif" /><br />
        test
      """

      hogehoge()
      return

    it "2ch以外のスレッドではsssp://リンクを無視する", ->
      example.a.data1.message = """
        sssp://img.2ch.net/ico/u_utyuu.gif<br>
        test
      """
      example.a.dom1.querySelector(".message").innerHTML = """
        sssp://img.2ch.net/ico/u_utyuu.gif<br>
        test
      """

      hogehoge()
      return

    it "thumbnail_supportedがonの時、対応サイトのサムネイル埋め込みを行う", ->
      spyOn(app.config, "get").andCallFake (key) ->
        if key is "thumbnail_supported"
          "on"
        else
          app.config.get.originalValue.call(@, key)

      example.a.data1.message = """
        http://www.youtube.com/watch?v=BlpKiZI_iL8<br>
        http://www.youtube.com/watch?gl=JP&v=BlpKiZI_iL8<br>
        http://youtu.be/BlpKiZI_iL8<br>
        http://www.nicovideo.jp/watch/sm4362091<br>
        http://nico.ms/sm4362091
      """.replace(/\n/g, "")
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="http://www.youtube.com/watch?v=BlpKiZI_iL8" target="_blank" class="has_thumbnail">
          http://www.youtube.com/watch?v=BlpKiZI_iL8
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://www.youtube.com/watch?v=BlpKiZI_iL8" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="https://img.youtube.com/vi/BlpKiZI_iL8/default.jpg" />
          </a>
        </div>
        <br>
        <a href="http://www.youtube.com/watch?gl=JP&v=BlpKiZI_iL8" target="_blank" class="has_thumbnail">
          http://www.youtube.com/watch?gl=JP&v=BlpKiZI_iL8
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://www.youtube.com/watch?gl=JP&v=BlpKiZI_iL8" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="https://img.youtube.com/vi/BlpKiZI_iL8/default.jpg" />
          </a>
        </div>
        <br>
        <a href="http://youtu.be/BlpKiZI_iL8" target="_blank" class="has_thumbnail">
          http://youtu.be/BlpKiZI_iL8
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://youtu.be/BlpKiZI_iL8" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="https://img.youtube.com/vi/BlpKiZI_iL8/default.jpg" />
          </a>
        </div>
        <br>
        <a href="http://www.nicovideo.jp/watch/sm4362091" target="_blank" class="has_thumbnail">
          http://www.nicovideo.jp/watch/sm4362091
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://www.nicovideo.jp/watch/sm4362091" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="http://tn-skr4.smilevideo.jp/smile?i=4362091" />
          </a>
        </div>
        <br>
        <a href="http://nico.ms/sm4362091" target="_blank" class="has_thumbnail">
          http://nico.ms/sm4362091
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://nico.ms/sm4362091" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="http://tn-skr4.smilevideo.jp/smile?i=4362091" />
          </a>
        </div>
      """.replace(/(?:\n|\u0020{2})/g, "")

      hogehoge()
      return

    it "thumbnail_supportedがon以外の時、対応サイトのサムネイル埋め込みを行わない", ->
      spyOn(app.config, "get").andCallFake (key) ->
        if key is "thumbnail_supported"
          "dummy"
        else
          app.config.get.originalValue.call(@, key)

      example.a.data1.message = """
        http://www.youtube.com/watch?v=BlpKiZI_iL8<br>
        http://youtu.be/BlpKiZI_iL8<br>
        http://www.nicovideo.jp/watch/sm4362091
      """.replace(/\n/g, "")
      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="http://www.youtube.com/watch?v=BlpKiZI_iL8" target="_blank">
          http://www.youtube.com/watch?v=BlpKiZI_iL8
        </a>
        <br>
        <a href="http://youtu.be/BlpKiZI_iL8" target="_blank">
          http://youtu.be/BlpKiZI_iL8
        </a>
        <br>
        <a href="http://www.nicovideo.jp/watch/sm4362091" target="_blank">
          http://www.nicovideo.jp/watch/sm4362091
        </a>
      """.replace(/(?:\n|\u0020{2})/g, "")

      hogehoge()
      return

    it "thumbnail_extがonの時リンク先のURLをサムネイルとして埋め込む", ->
      spyOn(app.config, "get").andCallFake (key) ->
        if key is "thumbnail_ext"
          "on"
        else
          app.config.get.originalValue.call(@, key)

      example.a.data1.message = """
        http://example.com/example.bmp
        http://example.com/example.gif
        http://example.com/example.jpg
        http://example.com/example.jpeg
        http://example.com/example.png
        http://example.com/example.webp
      """.replace(/\n/g, "<br>")

      fn = (ext) ->
        """
        <a href="http://example.com/example.#{ext}" target="_blank" class="has_thumbnail">
          http://example.com/example.#{ext}
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://example.com/example.#{ext}" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="http://example.com/example.#{ext}" />
          </a>
        </div>
        """.replace(/(?:\n|\u0020{2})/g, "")

      example.a.dom1.querySelector(".message").innerHTML = fn("bmp")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("gif")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("jpg")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("jpeg")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("png")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("webp")

      hogehoge()
      return

    it "thumbnail_extがon以外の時リンク先のURLをサムネイルとして埋め込まない", ->
      spyOn(app.config, "get").andCallFake (key) ->
        if key is "thumbnail_ext"
          "dummy"
        else
          app.config.get.originalValue.call(@, key)

      example.a.data1.message = """
        http://example.com/example.bmp
        http://example.com/example.gif
        http://example.com/example.jpg
        http://example.com/example.jpeg
        http://example.com/example.png
        http://example.com/example.webp
      """.replace(/\n/g, "<br>")

      fn = (ext) ->
        """
        <a href="http://example.com/example.#{ext}" target="_blank">
          http://example.com/example.#{ext}
        </a>
        """.replace(/(?:\n|\u0020{2})/g, "")

      example.a.dom1.querySelector(".message").innerHTML = fn("bmp")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("gif")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("jpg")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("jpeg")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("png")
      example.a.dom1.querySelector(".message").innerHTML += "<br>" + fn("webp")

      hogehoge()
      return

    it "一行の中に複数のURLが記述された場合、サムネイルも一行で表示する", ->
      spyOn(app.config, "get").andCallFake (key) ->
        if key in ["thumbnail_supported", "thumbnail_ext"]
          "on"
        else
          app.config.get.originalValue.call(@, key)

      example.a.data1.message = """
        http://youtu.be/BlpKiZI_iL8
        http://example.com/example.bmp
        http://example.com/example.gif
      """.replace(/\n/g, " ")

      example.a.dom1.querySelector(".message").innerHTML = """
        <a href="http://youtu.be/BlpKiZI_iL8" target="_blank" class="has_thumbnail">
          http://youtu.be/BlpKiZI_iL8
        </a> 
        <a href="http://example.com/example.bmp" target="_blank" class="has_thumbnail">
          http://example.com/example.bmp
        </a> 
        <a href="http://example.com/example.gif" target="_blank" class="has_thumbnail">
          http://example.com/example.gif
        </a>
        <br>
        <div class="thumbnail">
          <a href="http://youtu.be/BlpKiZI_iL8" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="https://img.youtube.com/vi/BlpKiZI_iL8/default.jpg" />
          </a>
        </div>
        <div class="thumbnail">
          <a href="http://example.com/example.bmp" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="http://example.com/example.bmp" />
          </a>
        </div>
        <div class="thumbnail">
          <a href="http://example.com/example.gif" target="_blank">
            <img src="/img/dummy_1x1.png" data-src="http://example.com/example.gif" />
          </a>
        </div>
      """.replace(/(?:\n|\u0020{2})/g, "")

      hogehoge()
      return
    return
  return
