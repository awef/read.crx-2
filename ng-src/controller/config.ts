///<reference path="../../lib/DefinitelyTyped/angularjs/angular.d.ts" />
///<reference path="../service/Env.ts" />

interface ConfigCtrlScope extends ng.IScope {
  env: App.Env;
}

angular
  .module("controller/config", ["service/Env"])
    .controller("ConfigCtrl", function ($scope: ConfigCtrlScope, env: App.Env) {
      $scope.env = env;
    });

