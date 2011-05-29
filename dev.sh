SOURCE_DIR="src"
watch () {
  make
  date
  inotifywait -r -e create,delete,move,close_write $SOURCE_DIR
  watch
}

watch
