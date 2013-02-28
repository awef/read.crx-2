///<reference path="Bookmark.ts" />

declare var openDatabase: any;

module app.Bookmark {
  "use strict";

  export class WebSQLEntryList extends SyncableEntryList {
    private dbName: string;
    private db:any;
    private readyDB = new app.Callbacks();
    ready = new app.Callbacks();

    constructor (dbName:string) {
      super();

      this.dbName = dbName;

      this.openDB();

      this.readyDB.add(() => {
        this.loadFromDB(() => {
          this.ready.call();
        });
      });

      this.ready.add(() => {
        //EntryListの変更をDBに反映する
        this.onChanged.add((e:BookmarkUpdateEvent) => {
          if (e.type === "DEL") {
            this.deleteFromDB(e.entry.url);
          }
          else {
            this.putToDB(e.entry);
          }
        });
      });
    }

    private sqlDataToEntry (data:any[]):app.Bookmark.Entry {
      var entry:app.Bookmark.Entry = {
        url: <string>data[0],
        title: <string>data[1],
        type: <string>data[2],
        bbsType: <string>data[3],
        resCount:  <number>data[4] || null,
        expired: <number>data[5] === 1,
        readState: null
      };

      if (
        typeof data[6] === "number" &&
        typeof data[7] === "number" &&
        typeof data[8] === "number"
      ) {
        entry.readState = {
          url: entry.url,
          received: <number>data[6],
          read: <number>data[7],
          last: <number>data[8]
        };
      }

      return entry;
    }

    private openDB ():void {
      var db = openDatabase(this.dbName, "", "WebSQLEntryList", 0);

      db.transaction(
        function (transaction) {
          transaction.executeSql([
            "CREATE TABLE IF NOT EXISTS EntryList(",
            "url TEXT NOT NULL PRIMARY KEY,",
            "title TEXT NOT NULL,",
            "type TEXT NOT NULL,",
            "bbsType TEXT NOT NULL,",
            "resCount INTEGER,",
            "expired INTEGER NOT NULL,",
            "readState_received INTEGER,",
            "readState_read INTEGER,",
            "readState_last INTEGER",
            ")"
          ].join(" "));
        },
        function () {
          app.criticalError("ブックマーク保存用DBのセットアップに失敗しました。");
        },
        () => {
          this.db = db;
          this.readyDB.call();
        }
      );
    }

    private loadFromDB (callback?:Function):void {
      this.readyDB.add(() => {
        this.db.readTransaction(
          (transaction) => {
            transaction.executeSql(
              "SELECT * FROM EntryList",
              [],
              (transaction, result) => {
                var key:number, val:any, length:number, entry:Entry;

                length = result.rows.length;
                for (key = 0; key < length; key++) {
                  val = result.rows.item(key)

                  entry = {
                    url: val.url,
                    type: val.type,
                    bbsType: val.bbsType,
                    title: val.title,
                    resCount: val.resCount,
                    readState: null,
                    expired: val.expired === 1
                  };

                  if (
                    typeof val.readState_received === "number" &&
                    typeof val.readState_read === "number" &&
                    typeof val.readState_last === "number"
                  ) {
                    entry.readState = {
                      url: val.url,
                      received: val.readState_received,
                      read: val.readState_read,
                      last: val.readState_last
                    };
                  }

                  this.add(entry);
                }

                if (callback) {
                  callback();
                }
              }
            );
          },
          function () {
            app.criticalError("ブックマーク保存用DBからのデータの読み込みに失敗しました。");
          }
        );
      });
    }

    private putToDB (entry:Entry, callback?:Function):void {
      this.readyDB.add(() => {
        this.db.transaction(
          function (transaction) {
            transaction.executeSql(
              "INSERT OR REPLACE INTO EntryList values(?, ?, ?, ?, ?, ?, ?, ?, ?)",
              [
                entry.url,
                entry.title,
                entry.type,
                entry.bbsType,
                entry.resCount || null,
                entry.expired ? 1 : 0,
                entry.readState ? entry.readState.received : null,
                entry.readState ? entry.readState.read: null,
                entry.readState ? entry.readState.last: null
              ]
            );
          },
          function () {
            app.log("error", "ブックマーク保存用データベースへのブックマークの保存に失敗しました。");
          },
          function () {
            if (callback) {
              callback();
            }
          }
        );
      });
    }

    private deleteFromDB (url:string, callback?:Function):void {
      this.readyDB.add(() => {
        this.db.transaction(
          function (transaction) {
            transaction.executeSql("DELETE FROM EntryList WHERE url = ?", [url]);
          },
          function () {
            app.log("error", "ブックマーク保存用データベースからのブックマークの削除に失敗しました。");
          },
          function () {
            if (callback) {
              callback();
            }
          }
        );
      });
    }
  }
}
