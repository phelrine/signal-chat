signals = {}
inputId = ""

addSignal = (data)->
  signal = new Signal(data.id, false, true)
  signals[signal.id] = signal
  $("#unfixed-signals").prepend(signal.canvas)

newSignal = (data)->
  signal = new Signal(data.id)
  signals[signal.id] = signal
  $("h1").after signal.canvas
  inputId = signal.id

socket = io.connect()

socket.on "connected", newSignal

socket.on "signal added", addSignal

socket.on "signal started", (data)-> signals[data.id]?.beginLine()

socket.on "signal ended", (data)-> signals[data.id]?.endLine()

socket.on 'signal posted', (data)->
  $("#fixed-signals").prepend $("##{data.id}")
  signals[data.id]?.fix()

socket.on 'signal removed', (data)-> $("##{data.id}").remove()

$(document).ready ->
  $("#post").click ->
    socket.emit 'new signal', {}, newSignal
    $("#fixed-signals").prepend $("##{inputId}")
    signals[inputId]?.fix()
    socket.emit 'signal post', id: inputId

class Signal
  constructor: (@id, @fixed = false, @readOnly = false)->
    @canvas = $("<canvas>")
      .attr
        id: @id
        width: "400px"
        height: "20px"

    $(@canvas).addClass "signal unfixed"
    @x = 0
    @y = 10
    @ctx = @canvas.get(0).getContext("2d")

    @canvas.mousedown =>
      return if @readOnly
      socket.emit('signal start', id: @id)
      @beginLine()

    @canvas.mouseup =>
      socket.emit('signal end', id: @id)
      @endLine()

  beginLine: ->
    return if @fixed
    @timer = setInterval (=>
      @ctx.beginPath()
      @ctx.moveTo(@x, @y)
      @ctx.lineTo(@x + 1, @y)
      @ctx.closePath()
      @ctx.stroke()
      @x += 1)
      , 20

  endLine: ->
    clearInterval(@timer)
    @x += 10

  fix: ->
    @fixed = true
    $(@canvas).removeClass("unfixed").addClass("fixed")
