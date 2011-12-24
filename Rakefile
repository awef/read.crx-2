def haml(src, output)
  sh "haml -q #{src} #{output}"
end

def scss(src, output)
  sh "scss --style compressed --no-cache #{src} #{output}"
end

def coffee(src, output)
  sh "cat #{src} | coffee -cbsp > #{output}"
end

p_cp = proc do |t|
  sh "cp #{t.prerequisites[0]} #{t.name}"
end

p_coffee = proc do |t|
  coffee(t.prerequisites.join(" "), t.name)
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

task :clean do
  sh "rm -rf debug"
  #jQuery
  cd "lib/jquery" do
    sh "git checkout -f"
    sh "make clean"
  end
end

task :default => [
  "debug",
  "debug/manifest.json",
  "debug/lib",
  "debug/app.js",
  "debug/app_core.js",
  "debug/cs_addlink.js",
  "debug/cs_search.js",
  :img,
  :ui,
  :view,
  :zombie,
  :write,
  :test,
  :jquery,
  :jail
]

directory "debug"

file "debug/manifest.json" => "src/manifest.json", &p_cp

file "debug/app_core.js" => FileList["src/core/*.coffee"], &p_coffee

file "debug/cs_search.js" => [
  "src/app.coffee",
  "src/core/url.coffee",
  "src/cs_search.coffee"
], &p_coffee

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
    "debug/img/star2_19x19.png",

    "debug/img/search2_19x19_777.png",
    "debug/img/star_19x19_333.png",
    "debug/img/link_19x19_333.png",
    "debug/img/reload_19x19_333.png",
    "debug/img/pencil_19x19_333.png",
    "debug/img/arrow_19x19_333.png",

    "debug/img/search2_19x19_aaa.png",
    "debug/img/star_19x19_ddd.png",
    "debug/img/link_19x19_ddd.png",
    "debug/img/reload_19x19_ddd.png",
    "debug/img/pencil_19x19_ddd.png",
    "debug/img/arrow_19x19_ddd.png"
  ]

  directory "debug/img"

  file "debug/img/read.crx_128x128.png" => "src/image/svg/read.crx.svg" do |t|
    sh "convert\
      -background transparent\
      -resize 96x96\
      -extent 128x128-16-16\
      src/image/svg/read.crx.svg #{t.name}"
  end

  file "debug/img/loading.svg" => "src/image/svg/loading.svg", &p_cp
}.call()

#ui
lambda {
  task :ui => ["debug/ui.css", "debug/ui.js"]

  file "debug/ui.css" => FileList["src/common.scss"].include("src/ui/*.scss") do |t|
    scss("src/ui/ui.scss", t.name)
  end

  file "debug/ui.js" => FileList["src/ui/*.coffee"], &p_coffee
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

  file "debug/zombie.js" => [
    "src/core/url.coffee",
    "src/core/cache.coffee",
    "src/core/read_state.coffee",
    "src/core/history.coffee",
    "src/core/bookmark.coffee",
    "src/zombie.coffee"
  ], &p_coffee
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

  file "debug/write/write.js" => [
    "src/core/url.coffee",
    "src/write/write.coffee"
  ], &p_coffee

  file "debug/write/cs_write.js" => [
    "src/app.coffee",
    "src/core/url.coffee",
    "src/write/cs_write.coffee"
  ], &p_coffee
}.call()

#Test
lambda {
  task :test => [
    "debug/test",
    "debug/test/qunit",
    "debug/test/qunit/qunit.js",
    "debug/test/qunit/qunit.css",
    "debug/test/qunit/qunit-step.js",
    "debug/test/test.html",
    "debug/test/test.js",
    "debug/test/message_test.html",
    "debug/test/message_test.js"
  ]

  directory "debug/test"

  directory "debug/test/qunit"
  file "debug/test/qunit/qunit.js" => "lib/qunit/qunit/qunit.js", &p_cp
  file "debug/test/qunit/qunit.css" => "lib/qunit/qunit/qunit.css", &p_cp
  file "debug/test/qunit/qunit-step.js" => "lib/qunit/addons/step/qunit-step.js", &p_cp

  file "debug/test/test.js" => FileList["src/test/test_*.coffee"], &p_coffee
}.call()

#jQuery
lambda {
  task :jquery => [
    "debug/lib/jquery",
    "debug/lib/jquery/jquery.min.js"
  ]

  directory "debug/lib/jquery"
  file "debug/lib/jquery/jquery.min.js" => "lib/jquery/dist/jquery.min.js", &p_cp
  file "lib/jquery/dist/jquery.min.js" => [
    "lib/jquery_license.patch",
    "lib/jquery_csp.patch",
    "lib/jquery_delegate_middle_click.patch",
    "lib/jquery/version.txt"
  ] do
    cd "lib/jquery" do
      sh "git checkout -f"
      sh "patch -p0 --no-backup-if-mismatch -i ../jquery_license.patch"
      sh "patch -p0 --no-backup-if-mismatch -i ../jquery_csp.patch"
      sh "patch -p0 --no-backup-if-mismatch -i ../jquery_delegate_middle_click.patch"
      sh "make min"
    end
  end
}.call()

#jail
lambda {
  task :jail => [
    "debug/lib/jail",
    "debug/lib/jail/jail.min.js"
  ]

  directory "debug/lib/jail"
  file "debug/lib/jail/jail.min.js" => "lib/jail/jail.min.js", &p_cp
}.call()
