###*
@namespace app
@class BBSMenu
@static
@requires jQuery
###
class app.AA
  @_openDB: ->
    unless @_openDBPromise?
      @_openDBPromise = $.Deferred((d) ->
        db = openDatabase("AA", "", "AA", 0)
        db.transaction(
          (transaction) ->
            transaction.executeSql """
              CREATE TABLE IF NOT EXISTS AA(
                id TEXT NOT NULL,
                title TEXT NOT NULL,
                content TEXT NOT NULL,
                date INTEGER NOT NULL
              )
            """
            return
          -> d.reject(); return
          -> d.resolve(db); return
        )
      ).promise()
    @_openDBPromise

  ###*
  @method add
  @param {String} id        AAを示す一意の文字列
  @param {String} title
  @param {String} content
  @param {Number} date
  @return {Promise}
  ###
  @add: (id, title, content, date) ->
    if app.assert_arg("AA.add", ["string", "string", "string", "number"], arguments)
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql(
            "INSERT INTO AA values(?, ?, ?, ?)"
            [id, title, content, date]
          )
          return
        ->
          app.log("error", "AA.add: データの格納に失敗しました")
          d.reject()
          return
        -> d.resolve(); return
      )
      return
    ).promise()
  
  ###*
  @method remove
  @param {String} id

  idに一致するAAを削除する。一つのAAだけが削除されるはず。
  ###
  @remove: (id) ->
    if app.assert_arg("AA.remove", ["string"], arguments)
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql("DELETE FROM AA WHERE id=?", [id])
          return
        ->
          app.log("error", "app.AA.remove: データの削除に失敗しました")
          d.reject()
          return
        ->
          d.resolve()
          return
      )
      return
    ).promise()

  ###*
  @method removeFromTitle
  @param {String} title

  titleに一致するすべてのAAを削除する。
  ###
  @removeFromTitle: (title) ->
    if app.assert_arg("AA.remove", ["string"], arguments)
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql("DELETE FROM AA WHERE title = ?", [title])
          return
        ->
          app.log("error", "app.AA.remove: トランザクション中断")
          d.reject()
          return
        ->
          d.resolve()
          return
      )
      return
    ).promise()

  ###*
  @method get
  @param {String} id
  @return {Promise}

  idが一致したAAを一つ返す。万一idが複数登録されてしまっているときは、
  dateの新しいものを返す。返されるデータはgetList関数とは違って
  配列ではない。
  ###
  @get: (id) ->
    if app.assert_arg("AA.get", ["string"], [id])
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.readTransaction(
        (transaction) ->
          transaction.executeSql(
            "SELECT * FROM AA WHERE id = ? ORDER BY date ASC"
            [id]
            (transaction, result) ->
              data = null
              if 0 < result.rows.length
                data = result.rows.item(0)
              d.resolve(data)
              return
          )
          return
        ->
          app.log("error", "AA.getList: Transaction aborted.")
          d.reject()
          return
      )
    ).promise()

  ###*
  @method update
  @param {String} id
  @param {String} title
  @param {String} content
  @param {Integer} date
  @return {Promise}

  AAを更新（データベースに上書き）する。
  ###
  @update: (id, title, content, date) ->
    if app.assert_arg("AA.update", ["string", "string", "string", "number"], [id, title, content, date])
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.transaction(
        (transaction) ->
          transaction.executeSql(
            "UPDATE AA SET title=?, content=?, date=? where id=?"
            [title, content, date, id]
          )
          return
        ->
          app.log("error", "app.AA.update: Transaction aborted.")
          d.reject()
          return
        ->
          d.resolve()
          return
      )
    ).promise()

  ###*
  @method getList
  @param {Number} offset
  @param {Number} limit
  @return {Promise}

  AAのリストを新しい順にoffset番目からlimit個分だけ取り出す。
  取り出される列はid, title, date
  ###
  @getList: (offset = -1, limit = -1) ->
    if app.assert_arg("AA.getList", ["number", "number"], [offset, limit])
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.readTransaction(
        (transaction) ->
          transaction.executeSql(
            "SELECT id,title,date FROM AA ORDER BY date DESC LIMIT ? OFFSET ?"
            [limit, offset]
            (transaction, result) ->
              data = []
              key = 0
              length = result.rows.length
              while key < length
                data.push(result.rows.item(key))
                key++
              d.resolve(data)
              return
          )
          return
        ->
          app.log("error", "AA.getList: トランザクション中断")
          d.reject()
          return
      )
    ).promise()

  ###*
  @method count
  @return {Promise}
  ###
  @count: ->
    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.readTransaction(
        (transaction) ->
          transaction.executeSql(
            "SELECT count() FROM AA"
            []
            (transaction, result) ->
              d.resolve(result.rows.item(0)["count()"])
              return
          )
          return
        ->
          app.log("error", "AA.count: トランザクション中断")
          d.reject()
          return
      )
    ).promise()

  ###*
  @method clear
  @param {Number} offset
  @return {Promise}
  ###
  @clear = (offset) ->
    if offset? and app.assert_arg("AA.clear", ["number"], arguments)
      return $.Deferred().reject().promise()

    @_openDB().pipe((db) -> $.Deferred (d) ->
      db.transaction(
        (transaction) ->
          if typeof offset is "number"
            transaction.executeSql(
              "DELETE FROM AA WHERE rowid < (SELECT rowid FROM AA ORDER BY date DESC LIMIT 1 OFFSET ?)"
              [offset - 1])
          else
            transaction.executeSql("DELETE FROM AA")
          return
        ->
          app.log("error", "app.AA.clear: トランザクション中断")
          d.reject()
          return
        ->
          d.resolve()
          return
      )
      return
    ).promise()

  ###*
  @method openEditPopup
  @param {Integer} id
  @param {String} title
  @param {String} content
  @return none

  AAを編集するためのポップアップを開く。idをundefinedにすると追加扱い。
  ###
  @openEditPopup = (id, title, content) ->
    url = "/view/editaa.html?v=#{app.manifest["version"]}"
    url += "&id=#{encodeURIComponent(id)}" if id?
    url += "&title=#{encodeURIComponent(title)}" if title?
    url += "&content=#{encodeURIComponent(content)}" if content?

    # 適当
    # TODO: マウス付近に表示させる
    top = 100
    left = 100
    height = 450
    width = 630
    window.open url, "Loading", 
      "toolbar=no, directories=no, status=no, menubar=no, scrollbars=no, " +
      "resizable=no, copyhistory=no, " +
      "width=#{width}px, height=#{height}px, top=#{top}px, left=#{left}px"
    return


