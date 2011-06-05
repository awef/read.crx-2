SOURCE_DIR="src"

while true
do
  make
  date
  inotifywait -r -e create,delete,move,close_write $SOURCE_DIR
done
