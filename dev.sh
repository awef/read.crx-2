SOURCE_DIR="code"
DEBUG_DIR="debug"

echo_red_bold () { echo -e "\e[1;31m$*\e[m"; }
echo_green_bold () { echo -e "\e[1;32m$*\e[m"; }

all_update () {
  echo_red_bold "start"

  mkdir -p $DEBUG_DIR
  rm -rf $DEBUG_DIR/*

  cp -r $SOURCE_DIR/lib/ $DEBUG_DIR/lib/
  cp -r $SOURCE_DIR/img/ $DEBUG_DIR/img/
  cp -r $SOURCE_DIR/test/ $DEBUG_DIR/test/
  cp $SOURCE_DIR/manifest.json $DEBUG_DIR/manifest.json
  cp $SOURCE_DIR/app.html $DEBUG_DIR/app.html

  sass --style compressed --no-cache $SOURCE_DIR/app.sass $DEBUG_DIR/app.css

  coffee -b -j -p -c ${SOURCE_DIR}/app.coffee ${SOURCE_DIR}/app.*.coffee > ${DEBUG_DIR}/app.js
  coffee -b -j -p -c ${SOURCE_DIR}/ui.*.coffee > ${DEBUG_DIR}/ui.js

  echo_green_bold "complete"
}

watch () {
  all_update
  inotifywait -r -e create,delete,modify,move $SOURCE_DIR
  watch
}

case $1 in
  "watch") watch ;;
  *) all_update ;;
esac
