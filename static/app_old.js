const FPS = 50;

const GAME_WIDTH = 730;
const GAME_HEIGHT = GAME_WIDTH/2;
const PIXELS_PER_UNIT = GAME_WIDTH/1000;
const COURT_Y = 4*GAME_HEIGHT/5;
const SLIME_RADIUS = 50;
const BALL_RADIUS = 15;

const MAX_VELOCITY_X = 15;
const MAX_VELOCITY_Y = 11;

var gamestate = {};

var canvas;
var ctx;

var interval = 1000/FPS;
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
// TODO: replace with enums
const KEYCODE_LEFT  = 37;
const KEYCODE_UP    = 38;
const KEYCODE_RIGHT = 39;
const KEYCODE_DOWN =  40;

const KEYCODES = [KEYCODE_LEFT, KEYCODE_RIGHT, KEYCODE_UP, KEYCODE_DOWN];

const LEFT = 0;
const RIGHT = 1;
const UP = 2;
const DOWN = 3;

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

function Slime(radius, color, leftLimit, rightLimit){
  return {
    radius: radius,
    color: color,
    x: 0,
    y: 0,
    velocityX: 0,
    velocityY: 0,
    leftLimit: leftLimit,
    rightLimit: rightLimit,
    render: function() {
      var xPix      = this.x * PIXELS_PER_UNIT;
      var yPix      = COURT_Y - (this.y * PIXELS_PER_UNIT);

      var radiusPix = this.radius * PIXELS_PER_UNIT;
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.arc(xPix, yPix, radiusPix, Math.PI, 2*Math.PI);
      ctx.fill();
    },
    update: function() {
      if(this.velocityX != 0) {
        this.x += this.velocityX;
        if(this.x - this.radius < this.leftLimit) {
          this.x = this.leftLimit + this.radius;
        } else if(this.x + this.radius > this.rightLimit) {
          this.x = this.rightLimit - this.radius;
        }
      }
      if(this.velocityY != 0 || this.y > 0) {
        this.y += this.velocityY;
        this.velocityY -= 1.2;
        if(this.y < 0) {
          this.y = 0;
          this.velocityY = 0;
        }
      }
    }
  };
}

function Ball(radius, color){
  return {
    radius:radius,
    color:color,
    x:0,
    y:0,
    velocityX:0,
    velocityY:0,
    render: function() {
      var xPix   = this.x * PIXELS_PER_UNIT;
      var yPix   = COURT_Y - (this.y * PIXELS_PER_UNIT);

      var radiusPix = this.radius * PIXELS_PER_UNIT + 2;
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.arc(xPix, yPix, radiusPix, 0, 2*Math.PI);
      ctx.fill();
    },
    update: function() {
      this.x += this.velocityX;
      this.y += this.velocityY;
      this.velocityY += -.5; // gravity
      if(this.velocityY < -MAX_VELOCITY_Y) {
        this.velocityY = -MAX_VELOCITY_Y;
      }
      
      this.collideSlime(gamestate.slimes[0]);
      this.collideSlime(gamestate.slimes[1]);
      /*
      gamestate.slimes.forEach(function(slime){
        this.collideSlime(slime); // FIX  
      });
      // how do scopes even work?
      */
      
      // detect wall collisions
      if(this.x - this.radius < 0) {
        this.x = this.radius;
        this.velocityX = -this.velocityX;
      }
      else if(this.x + this.radius > 1000) {
        this.x = 1000 - this.radius;
        this.velocityX = -this.velocityX;
      }
      if(this.y < 0) {
        if(this.x > 500) {
          initRound(true);
        } else {
          initRound(false);
        }
      }
    },
    collideSlime: function(slime) {
      var dx = this.x - slime.x;
      var dy = this.y - slime.y;
      var dist = Math.sqrt(dx * dx + dy * dy);
      //console.log("dist = " + dist);
      var dVelocityX = this.velocityX - slime.velocityX;
      var dVelocityY = this.velocityY - slime.velocityY;
      if(dy > 0 && dist < this.radius + slime.radius) {
        var oldBall = {x:this.x,y:this.y,velocityX:this.velocityX,velocityY:this.velocityY};
        this.x = slime.x + (slime.radius + this.radius) * dx / dist;
        this.y = slime.y + (slime.radius + this.radius) * dy / dist;
        
        var something = (dx * dVelocityX + dy * dVelocityY) / dist;
        if(something <= 0) {
          this.velocityX += slime.velocityX - 1.92 * dx * something / dist;
          this.velocityY += slime.velocityY - 1.92 * dy * something / dist;
          if(     this.velocityX < -MAX_VELOCITY_X) this.velocityX = -MAX_VELOCITY_X;
          else if(this.velocityX >  MAX_VELOCITY_X) this.velocityX =  MAX_VELOCITY_X;
          if(     this.velocityY < -MAX_VELOCITY_Y) this.velocityY = -MAX_VELOCITY_Y;
          else if(this.velocityY >  MAX_VELOCITY_Y) this.velocityY =  MAX_VELOCITY_Y;
        }
      }    
    }
  };
}

function emitKeys()
{
  var keys = KEYCODES.map(function(keyCode){
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
  // update slime velocities
  for(var id=0;id<numPlayers;id++){
    var keys = inputs[id][curFrame];
    var slime = gamestate.slimes[id];
    if(keys[LEFT]){
      if(keys[RIGHT]){
        slime.velocityX = 0;
      }else{
        slime.velocityX = -8;
      }
    } else if(keys[RIGHT]){
      slime.velocityX = 8;
    } else {
      slime.velocityX = 0;
    }

    if(slime.y == 0 && keys[UP]){
      slime.velocityY = 18;
    }
  }

  gamestate.slimes.forEach(function(slime){
    slime.update();
  });

  gamestate.ball.update();
}

function renderBackground()
{
  var courtHeight = GAME_HEIGHT/5;
  ctx.fillStyle='#0077ff'
  ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT-courtHeight);
  ctx.fillStyle='#ca6'
  ctx.fillRect(0, GAME_HEIGHT-courtHeight, GAME_WIDTH, courtHeight);
  ctx.fillStyle='#fff'
  ctx.fillRect(GAME_WIDTH/2-2,7*GAME_HEIGHT/10,4,GAME_HEIGHT/10+5);
}

function render() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  renderBackground();

  gamestate.slimes.forEach(function(slime){
    slime.render();
  });

  gamestate.ball.render();
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

 function initRound(server) {
    gamestate.ball.x = server ? 200 : 800;
    gamestate.ball.y = 200;
    gamestate.ball.velocityX = 0;
    gamestate.ball.velocityY = 0;

    gamestate.slimes[0].x = 200;
    gamestate.slimes[0].y = 0;
    gamestate.slimes[0].velocityX = 0;
    gamestate.slimes[0].velocityY = 0;

    gamestate.slimes[1].x = 800;
    gamestate.slimes[1].y = 0;
    gamestate.slimes[1].velocityX = 0;
    gamestate.slimes[1].velocityY = 0;
}

function initializeGame()
{
  // initialize canvas and render objects
  var gameDiv = document.getElementById('game');
  canvas = document.createElement('canvas');
  canvas.width = 730;
  canvas.height = 365;
  gameDiv.appendChild(canvas);
  
  ctx = canvas.getContext("2d");

  // initialize gamestate
  gamestate.slimes = [Slime(SLIME_RADIUS, '#f00', 0, 495), 
                      Slime(SLIME_RADIUS, '#0f0', 505, 1000)];
  gamestate.ball = Ball(BALL_RADIUS, '#ff0');

  initRound(true); // set up ball and player positionss

  // initialize inputs
  for(var i=0;i<buffer;i++){
    for(var j=0;j<numPlayers;j++){
      inputs[j][i] = Array.prototype.map(function(){return 0;}, KEYCODES);
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
