do ($ = jQuery) ->
  methods =
    scroll_to: (res_num, animate_flg, offset = -10) ->
      target = @container.childNodes[res_num - 1]
      if target
        return if @container.classList.contains("searching") and not target.classList.contains("search_hit")
        if animate_flg
          @$container.animate(scrollTop: target.offsetTop + offset)
        else
          @container.scrollTop = target.offsetTop + offset
      return

    get_read: ->
      container_bottom = @container.scrollTop + @container.clientHeight
      read = @container.children.length
      for res, key in @container.children
        if res.offsetTop > container_bottom
          read = key - 1
          break
      read

  $.fn.thread = (method, param...) ->
    unless @data("thread:this")?
      @data("thread:this", {
        $container: @
        container: @[0]
      })
    res = methods[method].apply(@data("thread:this"), param)
    if res is undefined then @ else res

  return
