app.boot "/zombie.html", ->
  if localStorage.zombie_read_state?
    array_of_read_state = JSON.parse(localStorage["zombie_read_state"])

    app.bookmark.promise_first_scan.done ->
      count = 0
      countdown = ->
        if --count is 0
          close()

      for read_state in array_of_read_state
        count += 2
        app.read_state.set(read_state).always(countdown)
        app.bookmark.update_read_state(read_state).always(countdown)

      return

    delete localStorage["zombie_read_state"]
  else
    close()
