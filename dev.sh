SOURCE_DIR="src"

while true
do
  clear
  date
  make
  inotifywait -r -e create,delete,move,close_write $SOURCE_DIR
done
