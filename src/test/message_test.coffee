window.addEventListener "load", ->
  frame_id = (location.search or "?frame").slice(1)

  frame_info =
    frame: [
      "frame_1"
      "frame_2"
    ]
    frame_1: [
      "frame_1_1"
    ]
    frame_2: [
      "frame_2_1"
      "frame_2_2"
      "frame_2_3"
    ]
    frame_2_2: [
      "frame_2_2_1"
    ]

  if frame_id of frame_info
    frame_info[frame_id].forEach (child_id) ->
      iframe = document.createElement("iframe")
      iframe.src = "?#{child_id}"
      document.body.appendChild(iframe)

  app.message.add_listener "message_test_ping", ->
    app.message.send("message_test_pong", source_id: frame_id)

  if frame_id is "frame_2"
    setTimeout ->
      app.message.send("message_test_ping", {})
    , 300
