///<reference path="../app.ts" />
///<reference path="URL.ts" />

module app {
  "use strict";

  export module Bookmark {
    export interface ReadState {
      url: string;
      received: number;
      read: number;
      last: number;
    }

    export interface Entry {
      url: string;
      title: string;
      type: string;
      bbsType: string;
      resCount: number;
      readState: ReadState;
      expired: bool;
    }

    export interface LegacyEntry {
      url: string;
      title: string;
      type: string;
      bbs_type: string;
      res_count: number;
      read_state: ReadState;
      expired: bool;
    }

    export function legacyToCurrent (legacy:LegacyEntry):Entry {
      var entry:Entry, readState:ReadState;

      entry = {
        url: app.URL.fix(legacy.url),
        title: legacy.title,
        type: legacy.type,
        bbsType: legacy.bbs_type,
        resCount: null,
        readState: null,
        expired: legacy.expired === true
      };

      if (typeof legacy.res_count === "number" && !isNaN(legacy.res_count)) {
        entry.resCount = legacy.res_count;
      }

      if (legacy.read_state) {
        readState = legacy.read_state;
        if (
          readState.url === entry.url &&
          typeof readState.received === "number" && !isNaN(readState.received) &&
          typeof readState.last === "number" && !isNaN(readState.last) &&
          typeof readState.read === "number" && !isNaN(readState.read)
        ) {
          entry.readState = readState;
        }
      }

      return entry;
    }

    export function currentToLegacy (entry:Entry):LegacyEntry {
      var legacy:LegacyEntry, readState:ReadState;

      legacy = {
        url: app.URL.fix(entry.url),
        title: entry.title,
        type: entry.type,
        bbs_type: entry.bbsType,
        res_count: null,
        read_state: null,
        expired: entry.expired === true
      };

      if (typeof entry.resCount === "number" && !isNaN(entry.resCount)) {
        legacy.res_count = entry.resCount;
      }

      if (entry.readState) {
        readState = entry.readState;
        if (
          readState.url === entry.url &&
          typeof readState.received === "number" && !isNaN(readState.received) &&
          typeof readState.last === "number" && !isNaN(readState.last) &&
          typeof readState.read === "number" && !isNaN(readState.read)
        ) {
          legacy.read_state = readState;
        }
      }

      return legacy;
    }

    export class EntryList {
      private cache: {[index:string]:Entry;} = {};
      private boardURLIndex: {[index:string]:string[];} = {};

      add (entry:Entry):void {
        var boardURL:string;

        if (!this.get(entry.url)) {
          entry = app.deepCopy(entry);

          this.cache[entry.url] = entry;

          if (entry.type === "thread") {
            boardURL = app.URL.threadToBoard(entry.url);
            if (!this.boardURLIndex[boardURL]) {
              this.boardURLIndex[boardURL] = [];
            }
            this.boardURLIndex[boardURL].push(entry.url);
          }
        }
      }

      update (entry:Entry):void {
        if (this.get(entry.url)) {
          entry = app.deepCopy(entry);

          this.cache[entry.url] = entry;
        }
      }

      del (url:string):void {
        var tmp:number, boardURL:string;

        url = app.URL.fix(url);

        if (this.cache[url]) {
          if (this.cache[url].type === "thread") {
            boardURL = app.URL.threadToBoard(url);
            if (this.boardURLIndex[boardURL]) {
              tmp = this.boardURLIndex[boardURL].indexOf(url);
              if (tmp !== -1) {
                this.boardURLIndex[boardURL].splice(tmp, 1);
              }
            }
          }

          delete this.cache[url];
        }
      }

      get (url:string):Entry {
        url = app.URL.fix(url);

        return this.cache[url] ? app.deepCopy(this.cache[url]) : null;
      }

      getAll ():Entry[] {
        var key:string, res = [];

        for (key in this.cache) {
          res.push(this.cache[key]);
        }

        return app.deepCopy(res);
      }

      getAllThreads ():Entry[] {
        var key:string, res = [];

        for (key in this.cache) {
          if (this.cache[key].type === "thread") {
            res.push(this.cache[key]);
          }
        }

        return app.deepCopy(res);
      }

      getAllBoards ():Entry[] {
        var key:string, res = [];

        for (key in this.cache) {
          if (this.cache[key].type === "board") {
            res.push(this.cache[key]);
          }
        }

        return app.deepCopy(res);
      }

      getThreadsByBoardURL (url:string):Entry[] {
        var res = [], key:number, threadURL:string;

        url = app.URL.fix(url);

        if (this.boardURLIndex[url]) {
          for (key = 0; threadURL = this.boardURLIndex[url][key]; key++) {
            res.push(this.get(threadURL));
          }
        }

        return app.deepCopy(res);
      }
    }
  }
}
