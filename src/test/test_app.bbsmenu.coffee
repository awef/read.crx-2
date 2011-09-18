module("app.bbsmenu.parse")

test "パースエラー、もしくはパース結果が空の場合はnullを返す", 4, ->
  deepEqual(app.bbsmenu.parse(""), null)
  deepEqual(app.bbsmenu.parse("test"), null)
  deepEqual(app.bbsmenu.parse("<BR><BR><B>地震</B><BR>"), null)
  deepEqual(app.bbsmenu.parse("<A HREF=http://hato.2ch.net/lifeline/>緊急自然災害</A> "), null)

test "bbsmenu.htmlをパース出来る", 1, ->
  html = """
    <BR><BR><B>地震</B><BR> 
    <A HREF=http://headline.2ch.net/bbynamazu/>地震headline</A><br> 
    <A HREF=http://toki.2ch.net/namazuplus/>地震速報</A><br> 
    <A HREF=http://hayabusa.2ch.net/eq/>臨時地震</A><br> 
    <A HREF=http://hayabusa.2ch.net/eqplus/>臨時地震+</A><br> 
    <A HREF=http://hato.2ch.net/lifeline/>緊急自然災害</A> 
  """
  deepEqual(app.bbsmenu.parse(html), [
    {
      title: "地震"
      board: [
        {url: "http://headline.2ch.net/bbynamazu/", title: "地震headline"}
        {url: "http://toki.2ch.net/namazuplus/", title: "地震速報"}
        {url: "http://hayabusa.2ch.net/eq/", title: "臨時地震"}
        {url: "http://hayabusa.2ch.net/eqplus/", title: "臨時地震+"}
        {url: "http://hato.2ch.net/lifeline/", title: "緊急自然災害"}
      ]
    }
  ])

test "不純物が混ざっていても問題無い", 1, ->
  html = """
    <html><awe,,>2,,qf,mp[]5[@:]
    <A HREF=http://headline.2ch.net/bbynamazu/>地震headline</A><br> 
    test
    <A HREF=http://headline.2ch.net/bbynamazu/>地震headline</A><br> 
    <BR><BR><B>地震</B><BR> 
    <A HREF=http://headline.2ch.net/bbynamazu/>地震headline</A><br> 
    
    <BR><BR><B>地震</B><BR> 
      
    <A HREF=http://headline.2ch.net/bbynamazu/>地震headline</A><br> 
    test
    <BR><BR><B>地震</B><BR> 
    <BR><BR><B>おすすめ</B><BR> 
    <A HREF=http://yuzuru.2ch.net/ftax/>ふるさと納税</A><br> 
  """
  deepEqual(app.bbsmenu.parse(html), [
    {
      title: "地震"
      board: [
        {url: "http://headline.2ch.net/bbynamazu/", title: "地震headline"}
      ]
    }
    {
      title: "おすすめ"
      board: [
        {url: "http://yuzuru.2ch.net/ftax/", title: "ふるさと納税"}
      ]
    }
  ])

test "実際には板やスレではない項目は除外される", 1, ->
  html = """
    <BR><BR><B>dummy</B><BR> 
    <A HREF=http://headline.2ch.net/dummy/>dummy</A><br> 
    <A HREF=http://info.2ch.net/wiki/>2chプロジェクト</A><br> 
    <A HREF=http://info.2ch.net/rank/>いろいろランク</A><br> 
    <A HREF=http://info.2ch.net/guide/adv.html>ガイドライン</A><br> 
    <A HREF=http://www.monazilla.org/ TARGET=_blank>2chツール</A><br> 
    <A HREF=http://www.domo2.net/ TARGET=_blank>domo2</A><br> 
    <A HREF=http://tatsu01.sakura.ne.jp/ TARGET=_blank>DAT2HTML</A><br> 
    <A HREF=http://monahokan.web.fc2.com/AAE/ TARGET=_blank>AAエディタ</A><br> 
    <A HREF=http://info.2ch.net/mag.html>2chメルマガ</A><BR> 
    <A HREF=http://www.megabbs.com/ TARGET=_blank>megabbs</A><br> 
    <A HREF=http://www.milkcafe.net/ TARGET=_blank>MILKCAFE</A><br> 
    <A HREF=http://svnews.jp/ TARGET=_blank>レンサバ比較</A><br> 
    <A HREF=http://ma-na.biz/ TARGET=_blank>ペンフロ</A><br> 
    <A HREF=http://headline.2ch.net/dummy/>dummy</A><br> 
    <BR><BR><B>dummy2</B><BR> 
    <A HREF=http://headline.2ch.net/dummy/>dummy</A><br> 
  """
  deepEqual(app.bbsmenu.parse(html), [
    {
      title: "dummy"
      board: [
        {url: "http://headline.2ch.net/dummy/", title: "dummy"}
        {url: "http://headline.2ch.net/dummy/", title: "dummy"}
      ]
    }
    {
      title: "dummy2",
      board: [
        {url: "http://headline.2ch.net/dummy/", title: "dummy"}
      ]
    }
  ])
