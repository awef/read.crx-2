SOURCE_DIR="src"

while true
do
  clear
  date
  rake
  inotifywait -r -e create,delete,move,close_write $SOURCE_DIR
done
