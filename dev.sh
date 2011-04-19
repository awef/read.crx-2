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
  cp -r $SOURCE_DIR/test/ $DEBUG_DIR/test/
  cp $SOURCE_DIR/manifest.json $DEBUG_DIR/manifest.json
  cp $SOURCE_DIR/app.html $DEBUG_DIR/app.html

  sass --style compressed --no-cache $SOURCE_DIR/app.sass $DEBUG_DIR/app.css

  coffee -o ${TEMP_DIR}/ -c ${SOURCE_DIR}/

  cat $SOURCE_DIR/app.js $SOURCE_DIR/app.*.js $TEMP_DIR/app.*.js > $DEBUG_DIR/app.js
  cat $SOURCE_DIR/ui.*.js $TEMP_DIR/ui.*.js > $DEBUG_DIR/ui.js

  rm -r $TEMP_DIR

  echo_green_bold "complete"
}

watch () {
  all_update
  while inotifywait -e create,delete,modify,move $SOURCE_DIR; do
    all_update
  done
}

case $1 in
  "watch") watch ;;
  *) all_update ;;
esac
