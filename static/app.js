var FPS = 60;

var gamestate = {};

var canvas;
var ctx;

var interval = 1000/FPS;
var lastTime = (new Date()).getTime();
var currentTime = 0;

var socket = io();

// keyboard input
var KEY_LEFT  = 37;
var KEY_UP    = 38;
var KEY_RIGHT = 39;
var KEY_DOWN =  40;

var keysDown = {};
addEventListener("keydown", function(e) {
  keysDown[e.keyCode] = true;
}, false);

addEventListener("keyup", function(e) {
  keysDown[e.keyCode] = false;
}, false);

function Rectangle(x, y, w, h){
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

function update()
{
  if (keysDown[KEY_LEFT]){
    gamestate.rect.x -= 10;
  }else if(keysDown[KEY_RIGHT]){
    gamestate.rect.x += 10;
  }

  if (keysDown[KEY_UP]){
    gamestate.rect.y -= 10;
  }else if(keysDown[KEY_DOWN]){
    gamestate.rect.y += 10;
  }

  socket.emit('update', {x: gamestate.rect.x, y: gamestate.rect.y});
}

function render() {
  // clear canvas
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.fillStyle = "rgb(200, 200, 200)";
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  gamestate.rect.render();
}

function loop(){
  window.requestAnimationFrame(loop);

  currentTime = (new Date()).getTime();
  delta = currentTime - lastTime;

  if(delta > interval){
    update();
    render();

    lastTime = currentTime;
  }  
}

function initializeGame()
{
  console.log("Hi!");

  // initialize canvas and render objects
  var gameDiv = document.getElementById('game');
  canvas = document.createElement('canvas');
  canvas.width = 750;
  canvas.height = 350;
  gameDiv.appendChild(canvas);
  
  ctx = canvas.getContext("2d");

  // initialize gamestate
  gamestate.rect = Rectangle(10, 10, 50, 50);

  loop();
}

socket.on('update', function(msg){
  gamestate.rect.x = msg.x;
  gamestate.rect.y = msg.y;
});

/*$(function () {
  var socket = io();
  $('form').submit(function(){
    socket.emit('chat message', $('#m').val());
    $('#m').val('');
    return false;
  });
  socket.on('chat message', function(msg){
    $('#messages').append($('<li>').text(msg));
  });
});*/