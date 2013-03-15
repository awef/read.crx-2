///<reference path="../app.ts" />
///<reference path="URL.ts" />
///<reference path="Bookmark.ts" />
///<reference path="Bookmark.WebSQLEntryList.ts" />
///<reference path="Bookmark.ChromeBookmarkEntryList.ts" />

declare interface app {
  read_state: any;
}

module app.Bookmark {
  "use strict";

  export class CompatibilityLayer {
    private webSQLEntryList: WebSQLEntryList;
    private firstScan = $.Deferred();
    promise_first_scan;

    constructor (webSQLEntryList: WebSQLEntryList) {
      this.webSQLEntryList = webSQLEntryList;
      this.promise_first_scan = this.firstScan.promise();

      this.webSQLEntryList.ready.add(() => {
        this.firstScan.resolve();
      });

      this.webSQLEntryList.onChanged.add((e) => {
        var legacyEntry: LegacyEntry = app.Bookmark.currentToLegacy(e.entry);

        switch (e.type) {
          case "ADD":
            app.message.send(
              "bookmark_updated",
              {type: "added", bookmark: legacyEntry, entry: e.entry}
            );
            break;
          case "TITLE":
            app.message.send(
              "bookmark_updated",
              {type: "title", bookmark: legacyEntry, entry: e.entry}
            );
            break;
          case "RES_COUNT":
            app.message.send(
              "bookmark_updated",
              {type: "res_count", bookmark: legacyEntry, entry: e.entry}
            );
            break;
          case "READ_STATE":
            app.message.send("read_state_updated", {
              "board_url": app.URL.threadToBoard(e.entry.url),
              "read_state": e.entry.readState
            });
            break;
          case "EXPIRED":
            app.message.send(
              "bookmark_updated",
              {type: "expired", bookmark: legacyEntry, entry: e.entry}
            );
            break;
          case "DEL":
            app.message.send(
              "bookmark_updated",
              {type: "removed", bookmark: legacyEntry, entry: e.entry}
            );
            break;
        }
      });

      // 鯖移転検出時処理
      app.message.addListener("detected_ch_server_move", (message) => {
        var entry:Entry, tmp;

        // 板ブックマーク更新
        if (entry = this.webSQLEntryList.get(message.before)) {
          this.webSQLEntryList.del(message.before);
          entry.url = message.after;
          this.webSQLEntryList.add(entry);
        }

        // スレブックマーク更新
        tmp = /^(http:\/\/\w+\.2ch\.net\/)/.exec(message.after)[1];
        this.webSQLEntryList.getThreadsByBoardURL(message.before)
          .forEach((entry) => {
            this.webSQLEntryList.del(entry.url);
            entry.url.replace(/^(http:\/\/\w+\.2ch\.net\/)/, tmp);
            this.webSQLEntryList.add(entry);
          });
      });
    }

    get (url:string):app.Bookmark.LegacyEntry {
      var entry = this.webSQLEntryList.get(url);

      if (entry) {
        return app.Bookmark.currentToLegacy(entry);
      }
      else {
        return null;
      }
    }

    get_by_board (boardURL:string):LegacyEntry[] {
      return (
        this.webSQLEntryList.getThreadsByBoardURL(boardURL)
          .map(function (entry:Entry):LegacyEntry {
            return app.Bookmark.currentToLegacy(entry);
          })
      );
    }

    get_all ():LegacyEntry[] {
      return (
        this.webSQLEntryList.getAll()
          .map(function (entry:Entry):LegacyEntry {
            return app.Bookmark.currentToLegacy(entry);
          })
      );
    }

    add (url:string, title:string, resCount?:number):void {
      var entry = app.Bookmark.ChromeBookmarkEntryList.URLToEntry(url);

      entry.title = title;

      app.read_state.get(entry.url).always((readState:ReadState) => {
        if (readState) {
          entry.readState = readState;
        }

        if (typeof resCount === "number") {
          entry.resCount = resCount;
        }
        else if (entry.readState) {
          entry.resCount = entry.readState.received;
        }

        this.webSQLEntryList.add(entry);
      });
    }

    remove (url:string):void {
      this.webSQLEntryList.del(url);
    }

    update_read_state (readState):void {
      var entry = this.webSQLEntryList.get(readState.url);

      if (entry) {
        entry.readState = readState;
        this.webSQLEntryList.update(entry);
      }
    }

    update_res_count (url:string, resCount:number):void {
      var entry = this.webSQLEntryList.get(url);

      if (entry) {
        entry.resCount = resCount;
        this.webSQLEntryList.update(entry);
      }
    }

    update_expired (url:string, expired:bool):void {
      var entry = this.webSQLEntryList.get(url);

      if (entry) {
        entry.expired = expired;
        this.webSQLEntryList.update(entry);
      }
    }
  }
}
