var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

app.use('/static', express.static('static'));

app.get('/', function(req, res){
  res.sendFile(__dirname + '/static/index.html');
});

io.on('connection', function(socket){
  console.log('connection established');
  socket.on('update', function(msg){
//    console.log('message: ' + msg.x + ' ' + msg.y);
    io.emit('update', msg);
  });
});

http.listen(3000, function(){
  console.log('listening on *:3000');
});

