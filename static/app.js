var FPS = 30;

var gamestate = {};

var canvas;
var ctx;

var interval = 1000./FPS;
var lastTime = (new Date()).getTime();
var currentTime = 0;
var curFrame = 0;

var socket = io();
var myId = -1;
var numPlayers = 2;
var inputs = [{}, {}]; // should replace dicts with large circular buffers
var buffer = 3;

// game parameters
const SPEED = 10;

// keyboard input
const KEY_LEFT  = 37;
const KEY_UP    = 38;
const KEY_RIGHT = 39;
const KEY_DOWN =  40;

const KEY_LIST = [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN];

var keysDown = {};
addEventListener("keydown", function(e) {
  keysDown[e.keyCode] = true;
}, false);

addEventListener("keyup", function(e) {
  keysDown[e.keyCode] = false;
}, false);

// player

function haveInputs(frame){
  return (inputs[0][frame] != null && inputs[1][frame] != null);
}

function Player(x, y, w, h){
  return {
    x: x,
    y: y,
    width: w,
    height: h,
    render: function() {
      ctx.fillStyle = '#ff0';
      ctx.fillRect(this.x, this.y, this.width, this.height);
    }
  };
}

function emitKeys()
{
  var keys = KEY_LIST.map(function(keyCode){
    return keysDown[keyCode];
  });
  socket.emit('update', {frame: curFrame, 
                         player: myId,
                         keys: keys});
  // update own keylist
  inputs[myId][curFrame + buffer] = keys;
}

function update()
{
  for(var id=0;id<numPlayers;id++){
    var keys = inputs[id][curFrame];
    if (keys[0]){
      gamestate.players[id].x -= SPEED;
    }else if(keys[1]){
      gamestate.players[id].x += SPEED;
    }

    if (keys[2]){
      gamestate.players[id].y -= SPEED;
    }else if(keys[3]){
      gamestate.players[id].y += SPEED;
    }
  }
}

function render() {
  // clear canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = "rgb(200, 200, 200)";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  gamestate.players.forEach(function(player){
    player.render();
  });
}

function loop(){
  window.requestAnimationFrame(loop);

  currentTime = (new Date()).getTime();
  delta = currentTime - lastTime;

  if(delta > interval){
    if(haveInputs(curFrame)){
      update();
      render();
      emitKeys();

      lastTime = currentTime;
      curFrame += 1;
    }else{
      console.log("Waiting for input for frame " + curFrame);
    }
  }  
}

function initializeGame()
{
  // initialize canvas and render objects
  var gameDiv = document.getElementById('game');
  canvas = document.createElement('canvas');
  canvas.width = 750;
  canvas.height = 350;
  gameDiv.appendChild(canvas);
  
  ctx = canvas.getContext("2d");

  // initialize gamestate
  gamestate.players = [Player(10, 10, 50, 50), Player(60, 60, 50, 50)];

  // initialize inputs
  for(var i=0;i<buffer;i++){
    for(var j=0;j<numPlayers;j++){
      inputs[j][i] = Array.prototype.map(function(){return 0;}, KEY_LIST);
    }
  }
}

// learn id
socket.on('init', function(msg){
  myId = msg.playerId;
});

socket.on('start', function(msg){
  loop();
});

socket.on('update', function(msg){
  inputs[msg.player][msg.frame + buffer] = msg.keys;
});
