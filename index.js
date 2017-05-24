var express = require('express');
var app = express();
var http = require('http').Server(app);
var io = require('socket.io')(http);

const numPlayers = 2;
var playerId = 0;

app.use('/static', express.static('static'));

app.get('/', function(req, res){
  res.sendFile(__dirname + '/static/index.html');
});

io.on('connection', function(socket){
  if(playerId >= numPlayers){
    console.log('game at player cap');
    socket.emit('gameFull');
  }else{
    console.log('player ' + playerId + ' connecting');
    socket.emit('init', {playerId: playerId});

    playerId++;
    if(playerId == numPlayers){
      io.emit('start');
    }

    socket.on('update', function(msg){
      io.emit('update', msg);
    });
  }
});

http.listen(3000, function(){
  console.log('listening on *:3000');
});

