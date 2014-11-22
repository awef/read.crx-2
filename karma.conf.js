module.exports = function(config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine'],
    files: [
      "bower_components/angular/angular.min.js",
      "bower_components/angular-mocks/angular-mocks.js",
      "debug/ng/script.js",
      "ng-spec/**/*.coffee",
      {pattern: 'debug/manifest.json', included: false, served: true}
    ],
    proxies: {
      "/manifest.json": "http://localhost:9876/base/debug/manifest.json"
    },
    preprocessors: {
      '**/*.coffee': ['coffee'],
      "debug/ng/script.js": ['coverage']
    },
    coffeePreprocessor: {
      options: {
        sourceMap: true
      }
    },
    reporters: ['coverage', 'progress'],
    port: 9876,
    colors: true,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['PhantomJS', 'Chrome', 'Firefox'],
    singleRun: false
  });
};
