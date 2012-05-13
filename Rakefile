task :default => [
  "debug",
  "debug/manifest.json",
  "debug/lib",
  "debug/app.js",
  "debug/app_core.js",
  "debug/cs_addlink.js",
  :img,
  :ui,
  :view,
  :zombie,
  :write,
  :build_test,
  :jquery
]

task :clean do
  sh "rm -f ./read.crx_2.zip"
  sh "rm -rf debug"
  #jQuery
  cd "lib/jquery" do
    sh "git checkout -f"
    sh "make clean"
  end
  cd "lib/jquery-mockjax" do
    sh "git checkout -f"
  end
end

task :pack do
  require "json"

  MANIFEST = JSON.parse(open("src/manifest.json").read)

  Rake::Task[:clean].invoke
  Rake::Task[:default].invoke
  sh "zip -9 -r -X -T ./read.crx_2.zip ./debug -x ./debug/test/\\*"
  sh "clamscan ./read.crx_2.zip"
  Rake::Task[:test].invoke
end

task :test, :filter do |t, args|
  require "cgi"

  url = "chrome-extension://#{debug_id}/test/test.html"
  if args[:filter]
    url += "?filter=#{CGI.escape(args[:filter])}"
  end
  sh "google-chrome #{url}"
end

def debug_id
  require "digest"
  hash = Digest::SHA256.hexdigest(File.absolute_path("debug"))
  hash[0...32].tr("0-9a-f", "a-p")
end

def haml(src, output)
  sh "haml -r ./haml_requirement.rb -q #{src} #{output}"
end

def scss(src, output)
  sh "scss --style compressed #{src} #{output}"
end

def coffee(src, output)
  if src.is_a? Array
    src = src.join(" ")
  end

  sh "coffee -cbj #{output} #{src}"
end

def file_coffee(target, src)
  file target => src do
    coffee(src, target)
  end
end

def file_copy(target, src)
  file target => src do
    sh "cp #{src} #{target}"
  end
end

rule ".html" => "%{^debug/,src/}X.haml" do |t|
  haml(t.prerequisites[0], t.name)
end

rule ".css" => "%{^debug/,src/}X.scss" do |t|
  scss(t.prerequisites[0], t.name)
end

rule ".js" => "%{^debug/,src/}X.coffee" do |t|
  coffee(t.prerequisites[0], t.name)
end

rule ".png" => "src/image/svg/%{_\\d+x\\d+(?:_\\w+)?$,}n.svg" do |t|
  /_(\d+)x(\d+)(?:_(\w*))?\.png$/ =~ t.name
  unless $3
    sh "convert\
      -background transparent\
      -resize #{$1}x#{$2}\
      #{t.prerequisites[0]} #{t.name}"
  else
    sh "convert\
      -background transparent\
      -resize #{$1}x#{$2}\
      -fuzz '50%'\
      -fill '##{$3}'\
      -opaque '#333'\
      #{t.prerequisites[0]} #{t.name}"
  end
end

directory "debug"

file_copy "debug/manifest.json", "src/manifest.json"

file_coffee "debug/app_core.js", FileList["src/core/*.coffee"]

#img
lambda {
  task :img => [
    "debug/img",
    "debug/img/read.crx_128x128.png",
    "debug/img/read.crx_48x48.png",
    "debug/img/read.crx_16x16.png",
    "debug/img/close_16x16.png",
    "debug/img/dummy_1x1.png",
    "debug/img/loading.svg",

    "debug/img/search2_19x19_777.png",
    "debug/img/star_19x19_333.png",
    "debug/img/star_19x19_007fff.png",
    "debug/img/reload_19x19_333.png",
    "debug/img/pencil_19x19_333.png",
    "debug/img/spanner_19x19_333.png",

    "debug/img/search2_19x19_aaa.png",
    "debug/img/star_19x19_ddd.png",
    "debug/img/star_19x19_f93.png",
    "debug/img/reload_19x19_ddd.png",
    "debug/img/pencil_19x19_ddd.png",
    "debug/img/spanner_19x19_ddd.png"
  ]

  directory "debug/img"

  file "debug/img/read.crx_128x128.png" => "src/image/svg/read.crx.svg" do |t|
    sh "convert\
      -background transparent\
      -resize 96x96\
      -extent 128x128-16-16\
      src/image/svg/read.crx.svg #{t.name}"
  end

  file_copy "debug/img/loading.svg", "src/image/svg/loading.svg"
}.call()

#ui
lambda {
  task :ui => ["debug/ui.css", "debug/ui.js"]

  file "debug/ui.css" => FileList["src/common.scss"].include("src/ui/*.scss") do |t|
    scss("src/ui/ui.scss", t.name)
  end

  file_coffee "debug/ui.js", FileList["src/ui/*.coffee"]
}.call()

#View
lambda {
  directory "debug/view"

  view = [
    "debug/view",
    "debug/view/app_proxy.js",
    "debug/view/module.js"
  ]

  FileList["src/view/*.haml"].each {|x|
    view.push(x.sub(/^src\//, "debug/").sub(/\.haml$/, ".html"))
  }

  FileList["src/view/*.coffee"].each {|x|
    view.push(x.sub(/^src\//, "debug/").sub(/\.coffee$/, ".js"))
  }

  FileList["src/view/*.scss"].each {|scss_path|
    css_path = scss_path.sub(/^src\//, "debug/").sub(/\.scss$/, ".css")
    view.push(css_path)
    file css_path => ["src/common.scss", scss_path] do |t|
      scss(scss_path, t.name)
    end
  }

  task :view => view
}.call()

#Zombie
lambda {
  task :zombie => ["debug/zombie.html", "debug/zombie.js"]

  file_coffee "debug/zombie.js", [
    "src/core/url.coffee",
    "src/core/cache.coffee",
    "src/core/read_state.coffee",
    "src/core/history.coffee",
    "src/core/bookmark.coffee",
    "src/zombie.coffee"
  ]
}.call()

#Write
lambda {
  task :write => [
    "debug/write",
    "debug/write/write.html",
    "debug/write/write.css",
    "debug/write/write.js",
    "debug/write/cs_write.js"
  ]

  directory "debug/write"

  file "debug/write/write.css" => [
      "src/common.scss",
      "src/write/write.scss"
    ] do |t|
    scss("src/write/write.scss", t.name)
  end

  file_coffee "debug/write/write.js", [
    "src/core/url.coffee",
    "src/write/write.coffee"
  ]

  file_coffee "debug/write/cs_write.js", [
    "src/app.coffee",
    "src/core/url.coffee",
    "src/write/cs_write.coffee"
  ]
}.call()

#Test
lambda {
  task :build_test => [
    "debug/test",
    "debug/test/qunit",
    "debug/test/qunit/qunit.js",
    "debug/test/qunit/qunit.css",
    "debug/test/qunit/qunit-step.js",
    "debug/test/qunit/qunit-measure.js",
    "debug/test/jquery.mockjax.js",
    "debug/test/test.html",
    "debug/test/test.js",
    "debug/test/message_test.html",
    "debug/test/message_test.js"
  ]

  directory "debug/test"

  directory "debug/test/qunit"
  file_copy "debug/test/qunit/qunit.js", "lib/qunit/qunit/qunit.js"
  file_copy "debug/test/qunit/qunit.css", "lib/qunit/qunit/qunit.css"
  file_copy "debug/test/qunit/qunit-step.js", "lib/qunit/addons/step/qunit-step.js"
  file_copy "debug/test/qunit/qunit-measure.js", "lib/qunit-measure/qunit-measure.js"

  file "debug/test/jquery.mockjax.js" => [
    "lib/jquery-mockjax/jquery.mockjax.js",
    "lib/jquery-mockjax_cancelable_etag.patch"
  ] do
    cd "lib/jquery-mockjax" do
      sh "git checkout -f"
      sh "git apply ../jquery-mockjax_cancelable_etag.patch"
    end
    cp "lib/jquery-mockjax/jquery.mockjax.js", "debug/test/jquery.mockjax.js"
  end

  file_coffee "debug/test/test.js", FileList["src/test/test_*.coffee"]
}.call()

#jQuery
lambda {
  task :jquery => [
    "debug/lib/jquery",
    "debug/lib/jquery/jquery.min.js"
  ]

  directory "debug/lib/jquery"
  file_copy "debug/lib/jquery/jquery.min.js", "lib/jquery/dist/jquery.min.js"
  file "lib/jquery/dist/jquery.min.js" => [
    "lib/jquery_license.patch",
    "lib/jquery_csp.patch",
    "lib/jquery_delegate_middle_click.patch",
    "lib/jquery/version.txt"
  ] do
    cd "lib/jquery" do
      sh "git checkout -f"
      sh "git apply ../jquery_license.patch"
      sh "git apply ../jquery_csp.patch"
      sh "git apply ../jquery_delegate_middle_click.patch"
      sh "make min"
    end
  end
}.call()
