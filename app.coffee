express = require("express")
routes = require("./routes")

app = module.exports = express.createServer()
io = require("socket.io").listen(app)

app.configure ->
  app.set "views", __dirname + "/views"
  app.set "view engine", "jade"
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use express.static(__dirname + "/public")

app.configure "development", ->
  app.use express.errorHandler(
    dumpExceptions: true
    showStack: true
  )

app.configure "production", ->
  app.use express.errorHandler()

app.get "/", routes.index
app.listen 3000
console.log "Express server listening on port %d in %s mode", app.address().port, app.settings.env

signalId = 0

newSignalId = ->
  id = signalId++
  "signal-#{id}"

io.sockets.on 'connection', (socket)->
  id = newSignalId()
  socket.set "input id", id
  socket.emit 'connected', id: id
  socket.broadcast.emit 'signal added', id: id

  socket.on 'new signal', (data, callback)->
    id = newSignalId()
    socket.broadcast.emit 'signal added', id: id
    socket.set "input id", id
    callback(id: id)

  socket.on 'signal start', (data) ->
    socket.broadcast.emit 'signal started', data

  socket.on 'signal end', (data) ->
    socket.broadcast.emit 'signal ended', data

  socket.on 'signal post', (data) ->
    socket.broadcast.emit 'signal posted', data

  socket.on 'disconnect', ()->
    socket.get 'input id', (err, id)->
      socket.broadcast.emit 'signal removed', id: id
