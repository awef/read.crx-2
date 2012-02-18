do ->
  modules = [
    "bbsmenu"
    "board"
    "board_title_solver"
    "bookmark"
    "cache"
    "history"
    "module"
    "ninja"
    "read_state"
    "thread"
    "url"
    "util"
  ]

  for module in modules
    app[module] = parent.app[module]
  return
