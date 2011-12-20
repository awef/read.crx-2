SRC = "src"
DBG = "debug"

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

rule ".html" => "%{^#{DBG}/,#{SRC}/}X.haml" do |t|
  haml(t.prerequisites[0], t.name)
end

rule ".css" => "%{^#{DBG}/,#{SRC}/}X.scss" do |t|
  scss(t.prerequisites[0], t.name)
end

rule ".js" => "%{^#{DBG}/,#{SRC}/}X.coffee" do |t|
  coffee(t.prerequisites[0], t.name)
end

rule ".png" => "#{SRC}/image/svg/%{_\\d+x\\d+(?:_\\w+)?$,}n.svg" do |t|
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
  sh "rm -rf #{DBG}"
  #jQuery
  cd "lib/jquery" do
    sh "git checkout -f"
    sh "make clean"
  end
end

task :default => [
  DBG,
  "#{DBG}/manifest.json",
  "#{DBG}/lib",
  "#{DBG}/app.js",
  "#{DBG}/app_core.js",
  "#{DBG}/cs_addlink.js",
  "#{DBG}/cs_search.js",
  :img,
  :ui,
  :view,
  :zombie,
  :write,
  :test,
  :jquery,
  :jail
]

directory DBG

file "#{DBG}/manifest.json" => "#{SRC}/manifest.json", &p_cp

file "#{DBG}/app_core.js" => FileList["#{SRC}/core/*.coffee"], &p_coffee

file "#{DBG}/cs_search.js" => [
  "#{SRC}/app.coffee",
  "#{SRC}/core/url.coffee",
  "#{SRC}/cs_search.coffee"
], &p_coffee

#img
lambda {
  task :img => [
    "#{DBG}/img",
    "#{DBG}/img/read.crx_128x128.png",
    "#{DBG}/img/read.crx_48x48.png",
    "#{DBG}/img/read.crx_16x16.png",
    "#{DBG}/img/close_16x16.png",
    "#{DBG}/img/dummy_1x1.png",
    "#{DBG}/img/loading.svg",
    "#{DBG}/img/star2_19x19.png",

    "#{DBG}/img/search2_19x19_777.png",
    "#{DBG}/img/star_19x19_333.png",
    "#{DBG}/img/link_19x19_333.png",
    "#{DBG}/img/reload_19x19_333.png",
    "#{DBG}/img/pencil_19x19_333.png",
    "#{DBG}/img/arrow_19x19_333.png",

    "#{DBG}/img/search2_19x19_aaa.png",
    "#{DBG}/img/star_19x19_ddd.png",
    "#{DBG}/img/link_19x19_ddd.png",
    "#{DBG}/img/reload_19x19_ddd.png",
    "#{DBG}/img/pencil_19x19_ddd.png",
    "#{DBG}/img/arrow_19x19_ddd.png"
  ]

  directory "#{DBG}/img"

  file "#{DBG}/img/read.crx_128x128.png" => "#{SRC}/image/svg/read.crx.svg" do |t|
    sh "convert\
      -background transparent\
      -resize 96x96\
      -extent 128x128-16-16\
      #{SRC}/image/svg/read.crx.svg #{t.name}"
  end

  file "#{DBG}/img/loading.svg" => "#{SRC}/image/svg/loading.svg", &p_cp
}.call()

#ui
lambda {
  task :ui => ["#{DBG}/ui.css", "#{DBG}/ui.js"]

  file "#{DBG}/ui.css" => FileList["#{SRC}/common.scss"].include("#{SRC}/ui/*.scss") do |t|
    scss("#{SRC}/ui/ui.scss", t.name)
  end

  file "#{DBG}/ui.js" => FileList["#{SRC}/ui/*.coffee"], &p_coffee
}.call()

#View
lambda {
  directory "#{DBG}/view"

  view = [
    "#{DBG}/view",
    "#{DBG}/view/app_proxy.js",
    "#{DBG}/view/module.js"
  ]

  FileList["#{SRC}/view/*.haml"].each {|x|
    view.push(x.sub(/^#{SRC}\//, "#{DBG}/").sub(/\.haml$/, ".html"))
  }

  FileList["#{SRC}/view/*.coffee"].each {|x|
    view.push(x.sub(/^#{SRC}\//, "#{DBG}/").sub(/\.coffee$/, ".js"))
  }

  FileList["#{SRC}/view/*.scss"].each {|scss_path|
    css_path = scss_path.sub(/^#{SRC}\//, "#{DBG}/").sub(/\.scss$/, ".css")
    view.push(css_path)
    file css_path => ["#{SRC}/common.scss", scss_path] do |t|
      scss(scss_path, t.name)
    end
  }

  task :view => view
}.call()

#Zombie
lambda {
  task :zombie => ["#{DBG}/zombie.html", "#{DBG}/zombie.js"]

  file "#{DBG}/zombie.js" => [
    "#{SRC}/core/url.coffee",
    "#{SRC}/core/cache.coffee",
    "#{SRC}/core/read_state.coffee",
    "#{SRC}/core/history.coffee",
    "#{SRC}/core/bookmark.coffee",
    "#{SRC}/zombie.coffee"
  ], &p_coffee
}.call()

#Write
lambda {
  task :write => [
    "#{DBG}/write",
    "#{DBG}/write/write.html",
    "#{DBG}/write/write.css",
    "#{DBG}/write/write.js",
    "#{DBG}/write/cs_write.js"
  ]

  directory "#{DBG}/write"

  file "#{DBG}/write/write.css" => [
      "#{SRC}/common.scss",
      "#{SRC}/write/write.scss"
    ] do |t|
    scss("#{SRC}/write/write.scss", t.name)
  end

  file "#{DBG}/write/write.js" => [
    "#{SRC}/core/url.coffee",
    "#{SRC}/write/write.coffee"
  ], &p_coffee

  file "#{DBG}/write/cs_write.js" => [
    "#{SRC}/app.coffee",
    "#{SRC}/core/url.coffee",
    "#{SRC}/write/cs_write.coffee"
  ], &p_coffee
}.call()

#Test
lambda {
  task :test => [
    "#{DBG}/test",
    "#{DBG}/test/qunit",
    "#{DBG}/test/test.html",
    "#{DBG}/test/test.js",
    "#{DBG}/test/message_test.html",
    "#{DBG}/test/message_test.js"
  ]

  directory "#{DBG}/test"

  file "#{DBG}/test/qunit" => FileList["lib/qunit/qunit/**/*"] do
    sh "rm -rf #{DBG}/test/qunit"
    sh "cp -r lib/qunit/qunit #{DBG}/test"
  end

  file "#{DBG}/test/test.js" => FileList["#{SRC}/test/test_*.coffee"], &p_coffee
}.call()

#jQuery
lambda {
  task :jquery => [
    "#{DBG}/lib/jquery",
    "#{DBG}/lib/jquery/jquery.min.js"
  ]

  directory "#{DBG}/lib/jquery"
  file "#{DBG}/lib/jquery/jquery.min.js" => "lib/jquery/dist/jquery.min.js", &p_cp
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
    "#{DBG}/lib/jail",
    "#{DBG}/lib/jail/jail.min.js"
  ]

  directory "#{DBG}/lib/jail"
  file "#{DBG}/lib/jail/jail.min.js" => "lib/jail/jail.min.js", &p_cp
}.call()
