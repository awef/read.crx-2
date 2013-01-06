module app {
  export module URL {
    export function fix (url:string):string {
      return (
        url
          // スレ系 誤爆する事は考えられないので、パラメータ部分をバッサリ切ってしまう
          .replace(/^(http:\/\/[\w\.]+\/test\/read\.cgi\/\w+\/\d+).*?$/, "$1/")
          .replace(/^(http:\/\/\w+\.machi\.to\/bbs\/read\.cgi\/\w+\/\d+).*?$/, "$1/")
          .replace(/^(http:\/\/jbbs\.livedoor\.jp\/bbs\/read\.cgi\/\w+\/\d+\/\d+).*?$/, "$1/")
          // 板系 完全に誤爆を少しでも減らすために、パラメータ形式も限定する
          .replace(/^(http:\/\/[\w\.]+\/\w+\/)(?:#.*)?$/, "$1")
          .replace(/^(http:\/\/jbbs\.livedoor\.jp\/\w+\/\d+\/)(?:#.*)?$/, "$1")
      );
    }

    export interface GuessResult {
      type: string;
      bbsType: string;
    }
    export function guessType (url:string):GuessResult {
      url = fix(url);

      if (/^http:\/\/jbbs\.livedoor\.jp\/bbs\/read\.cgi\/\w+\/\d+\/\d+\/$/.test(url)) {
        return {type: "thread", bbsType: "jbbs"};
      }
      else if (/^http:\/\/jbbs\.livedoor\.jp\/\w+\/\d+\/$/.test(url)) {
        return {type: "board", bbsType: "jbbs"};
      }
      else if (/^http:\/\/\w+\.machi\.to\/bbs\/read\.cgi\/\w+\/\d+\/$/.test(url)) {
        return {type: "thread", bbsType: "machi"};
      }
      else if (/^http:\/\/\w+\.machi\.to\/\w+\/$/.test(url)) {
        return {type: "board", bbsType: "machi"};
      }
      else if (/^http:\/\/[\w\.]+\/test\/read\.cgi\/\w+\/\d+\/$/.test(url)) {
        return {type: "thread", bbsType: "2ch"};
      }
      else if (/^http:\/\/(?:find|info|p2|ninja)\.2ch\.net\/\w+\/$/.test(url)) {
        return {type: "unknown", bbsType: "unknown"};
      }
      else if (/^http:\/\/[\w\.]+\/\w+\/$/.test(url)) {
        return {type: "board", bbsType: "2ch"};
      }
      else {
        return {type: "unknown", bbsType: "unknown"};
      }
    }

    export function tsld (url:string):string {
      var res:any;

      res = /^https?:\/\/(?:\w+\.)*(\w+\.\w+)\//.exec(url);
      return res ? res[1] : "";
    }

    export function threadToBoard (url:string):string {
      return (
        fix(url)
          .replace(/^http:\/\/([\w\.]+)\/(?:test|bbs)\/read\.cgi\/(\w+)\/\d+\/$/, "http://$1/$2/")
          .replace(/^http:\/\/jbbs\.livedoor\.jp\/bbs\/read\.cgi\/(\w+)\/(\d+)\/\d+\/$/, "http://jbbs.livedoor.jp/$1/$2/")
      );
    }

    function _parseQuery (query:string):{[index:string]:any;} {
      var data:{[index:string]:any;};

      data = {};

      query.split("&").forEach(function (segment) {
        var tmp:any;

        tmp = segment.split("=");

        if (tmp[1]) {
          data[decodeURIComponent(tmp[0])] = decodeURIComponent(tmp[1]);
        }
        else {
          data[decodeURIComponent(tmp[0])] = true;
        }
      });

      return data;
    }

    export function parseQuery (url:string):{[index:string]:any;} {
      var tmp;

      tmp = /\?([^#]+)(:?\#.*)?$/.exec(url);
      return tmp ? _parseQuery(tmp[1]) : {};
    }

    export function parseHashQuery (url:string):{[index:string]:any;} {
      var tmp;

      tmp = /#(.+)$/.exec(url);
      return tmp ? _parseQuery(tmp[1]) : {};
    }

    export function buildQueryString (data:{[index:string]:any;}) {
      var str:string, key:string, val:any;

      str = "";

      for (key in data) {
        val = data[key];

        if (val === true) {
          str += "&" + encodeURIComponent(key);
        }
        else {
          str += "&" + encodeURIComponent(key) + "=" + encodeURIComponent(val);
        }
      }

      return str.slice(1);
    }
  }
}

// 互換性確保部分
module app {
  export module url {
    export var fix = app.URL.fix;

    export function guess_type (url):{type: string; bbs_type: string;} {
      var tmp:app.URL.GuessResult;

      tmp = app.URL.guessType(url);

      return {
        type: tmp.type,
        bbs_type: tmp.bbsType
      };
    }

    export var tsld = app.URL.tsld;
    export var thread_to_board = app.URL.threadToBoard;
    export var parse_query = app.URL.parseQuery;
    export var parse_hashquery = app.URL.parseHashQuery;
    export var build_param = app.URL.buildQueryString;
  }
}
