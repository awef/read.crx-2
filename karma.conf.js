module.exports = function(config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine'],
    files: [
      "bin/lib/angularjs/angular.min.js",
      "bin/script.js",
      "bower_components/angular-mocks/angular-mocks.js",
      "spec/**/*.coffee"
    ],
    preprocessors: {
      '**/*.coffee': ['coffee'],
      "bin/script.js": ['coverage']
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
