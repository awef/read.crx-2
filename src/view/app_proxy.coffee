do ->
  modules = [
    "board"
    "bookmark"
    "cache"
    "history"
    "module"
    "ninja"
    "read_state"
    "url"
    "util"
  ]

  for module in modules
    app[module] = parent.app[module]
  return
