///<reference path="../../lib/DefinitelyTyped/angularjs/angular.d.ts" />

module App {
  export interface Env {
    production: boolean;
    development: boolean;
    test: boolean;
    appName: string;
    appVersion: string;
    platform: string;
  }
}

angular.module("service/Env", []).factory("env", function () {
  var env: App.Env = {
    production: null,
    development: null,
    test: null,
    appName: null,
    appVersion: null,
    platform: null
  };

  env.test = "jasmine" in window;
  env.development = !this.test; // TODO 現段階では実装不可
  env.production = false; // TODO 現段階では実装不可

  (function () {
    var xhr = new XMLHttpRequest(), manifest;
    xhr.open("GET", "/manifest.json", false);
    xhr.send();
    manifest = JSON.parse(xhr.responseText);

    env.appName = manifest.name;
    env.appVersion = manifest.version;
  })();

  env.platform = navigator.userAgent;

  Object.freeze(env);

  return env;
});

