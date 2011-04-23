SOURCE_DIR="code"
DEBUG_DIR="debug"
TEMP_DIR="temp"

echo_red_bold () { echo -e "\e[1;31m$*\e[m"; }
echo_green_bold () { echo -e "\e[1;32m$*\e[m"; }

all_update () {
  echo_red_bold "start"

  mkdir -p $DEBUG_DIR $TEMP_DIR
  rm -rf $DEBUG_DIR/* $TEMP_DIR/*

  cp -r $SOURCE_DIR/lib/ $DEBUG_DIR/lib/
  
  cp -r $SOURCE_DIR/img/ $DEBUG_DIR/img/
  
  mkdir $DEBUG_DIR/test/
  cp -r $SOURCE_DIR/test/qunit/ $DEBUG_DIR/test/qunit/
  cp $SOURCE_DIR/test/test.html $DEBUG_DIR/test/test.html
  
  cp $SOURCE_DIR/manifest.json $DEBUG_DIR/manifest.json
  
  cp $SOURCE_DIR/app.html $DEBUG_DIR/app.html

  sass --style compressed --no-cache $SOURCE_DIR/app.sass $DEBUG_DIR/app.css

  coffee -b -o ${TEMP_DIR}/ -c ${SOURCE_DIR}/ ${SOURCE_DIR}/test/

  cat $TEMP_DIR/app.js $TEMP_DIR/app.*.js > $DEBUG_DIR/app.js
  cat $TEMP_DIR/ui.*.js > $DEBUG_DIR/ui.js
  cat $TEMP_DIR/test.*.js > $DEBUG_DIR/test/test.js

  rm -r $TEMP_DIR
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
