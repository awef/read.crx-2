do ->
  modules = [
    "board"
    "bookmark"
    "module"
    "ninja"
    "read_state"
    "url"
    "util"
  ]

  for module in modules
    app[module] = parent.app[module]
  return
