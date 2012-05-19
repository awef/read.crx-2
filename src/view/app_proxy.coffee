do ->
  modules = [
    "board"
    "bookmark"
    "cache"
    "module"
    "ninja"
    "read_state"
    "url"
    "util"
  ]

  for module in modules
    app[module] = parent.app[module]
  return
