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
  }
}
