import * as io from 'socket.io-client';

const FPS:number = 50;

const GAME_WIDTH:number = 730;
const GAME_HEIGHT:number = GAME_WIDTH/2;
const PIXELS_PER_UNIT:number = GAME_WIDTH/1000;
const COURT_Y:number = 4*GAME_HEIGHT/5;
const SLIME_RADIUS:number = 50;
const BALL_RADIUS:number = 15;

const MAX_VELOCITY_X:number = 15;
const MAX_VELOCITY_Y:number = 11;

const NUM_PLAYERS = 2;
const BUFFER = 3;

namespace NetworkGame{
  let gameState:GameState;

  let canvas: HTMLCanvasElement;
  let ctx: CanvasRenderingContext2D;

  let interval:number = 1000/FPS;
  let lastTime = (new Date()).getTime();
  let currentTime = 0;
  let curFrame = 0;

  let socket = io();
  let myId = -1;
  let inputs:InputBuffer; // should replace dicts with large circular buffers

  export interface GameState {
    render(ctx:CanvasRenderingContext2D, 
           canvas: HTMLCanvasElement):void;
    update(inputs:InputState):void;
  }

  // keyboard input

  export enum Input {
    Left,
    Up,
    Right,
    Down
  }
  const NUM_INPUTS = Object.keys(Input).length/2;

  interface KeyMapping {
    [keycode: number] : Input;
  }

  const KEY_MAP:KeyMapping = {
    37: Input.Left,
    38: Input.Up,
    39: Input.Right,
    40: Input.Down
  };

  export interface InputBuffer {
    [frame: number]: InputState;
  }

  export interface InputState {
    [playerId: number]: PlayerInput;
  }

  export interface PlayerInput {
    [input: number]: boolean; // really should be [input: Input]: boolean, 
                              // but typescript doesn't allow indexing by Enums
                              // for some reason.
  }

  function newPlayerInput(copy?:PlayerInput):PlayerInput {
    const returnState:PlayerInput = {};
    for(let i=0;i<NUM_INPUTS;i++){
      if(copy == undefined){
        returnState[i] = false;
      }else{
        returnState[i] = copy[i];
      }
    }

    return returnState;
  }


  let playerInput:PlayerInput = {};
  addEventListener("keydown", function(e) {
    if(e.keyCode in KEY_MAP){
      playerInput[KEY_MAP[e.keyCode]] = true;
    }
  }, false);

  addEventListener("keyup", function(e) {
    if(e.keyCode in KEY_MAP){
      playerInput[KEY_MAP[e.keyCode]] = false;
    }
  }, false);



  function emitKeys()
  {
    socket.emit('update', {frame: curFrame, 
                          player: myId,
                          inputs: playerInput});
    // update own keylist
    inputs[curFrame + BUFFER][myId] = newPlayerInput(playerInput);
  }

  function haveInputs(frame: number){
    return (inputs[frame][0] != null && inputs[frame][1] != null);
  }

  function loop(){
    window.requestAnimationFrame(loop);

    currentTime = (new Date()).getTime();
    let delta = currentTime - lastTime;

    if(delta > interval){
      if(haveInputs(curFrame)){
        gameState.update(inputs[curFrame]);
        gameState.render(ctx, canvas);
        emitKeys();

        lastTime = currentTime;
        curFrame += 1;
      }else{
        console.log("Waiting for input for frame " + curFrame);
      }
    }  
  }

  export function initializeGame()
  {
    // initialize canvas and render objects
    let gameDiv = document.getElementById('game') as HTMLElement;
    canvas = document.createElement('canvas');
    canvas.width = 730;
    canvas.height = 365;
    gameDiv.appendChild(canvas);
    
    ctx = canvas.getContext("2d")!;

    gameState = new SlimeVolleyball.Game();

    // initialize inputs
    for(let i=0;i<BUFFER;i++){
      for(let j=0;j<NUM_PLAYERS;j++){
        inputs[i][j] = newPlayerInput();
      }
    }
  }

  interface InitMessage {
    playerId: number;
  }

  interface StartMessage {
    // empty for now
  }

  interface UpdateMessage {
    player: number;
    frame: number;
    inputs: PlayerInput;
  }

  // learn id
  socket.on('init', function(msg: InitMessage){
    myId = msg.playerId;
  });

  socket.on('start', function(msg: StartMessage){
    loop();
  });

  socket.on('update', function(msg: UpdateMessage){
    inputs[msg.frame + BUFFER][msg.player] = msg.inputs;
  });
}

namespace SlimeVolleyball
{
  import Input = NetworkGame.Input;

  export class Game implements NetworkGame.GameState {
    slimes: Slime[];
    ball: Ball;

    constructor () {
      // initialize gamestate
      this.slimes = [new Slime(SLIME_RADIUS, '#f00', 0, 495, this), 
                    new Slime(SLIME_RADIUS, '#0f0', 505, 1000, this)];
      this.ball = new Ball(BALL_RADIUS, '#ff0', this);

      this.initRound(true); // set up ball and player positions
    }

    initRound(server: boolean) {
      this.ball.x = server ? 200 : 800;
      this.ball.y = 200;
      this.ball.velocityX = 0;
      this.ball.velocityY = 0;

      this.slimes[0].x = 200;
      this.slimes[0].y = 0;
      this.slimes[0].velocityX = 0;
      this.slimes[0].velocityY = 0;

      this.slimes[1].x = 800;
      this.slimes[1].y = 0;
      this.slimes[1].velocityX = 0;
      this.slimes[1].velocityY = 0;
    }

    update(inputs: NetworkGame.InputState) {
      // inputs = inputs[id][curFrame]
      // update slime velocities
      for(let id=0;id<NUM_PLAYERS;id++){
        let keys = inputs[id];
        let slime = this.slimes[id];
        if(keys[Input.Left]){
          if(keys[Input.Right]){
            slime.velocityX = 0;
          }else{
            slime.velocityX = -8;
          }
        } else if(keys[Input.Right]){
          slime.velocityX = 8;
        } else {
          slime.velocityX = 0;
        }

        if(slime.y == 0 && keys[Input.Up]){
          slime.velocityY = 18;
        }
      }

      this.slimes.forEach(function(slime){
        slime.update();
      });

      this.ball.update();
    }

    render(ctx: CanvasRenderingContext2D, canvas:HTMLCanvasElement) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      const courtHeight = GAME_HEIGHT/5;
      ctx.fillStyle='#0077ff'
      ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT-courtHeight);
      ctx.fillStyle='#ca6'
      ctx.fillRect(0, GAME_HEIGHT-courtHeight, GAME_WIDTH, courtHeight);
      ctx.fillStyle='#fff'
      ctx.fillRect(GAME_WIDTH/2-2,7*GAME_HEIGHT/10,4,GAME_HEIGHT/10+5);

      this.slimes.forEach(function(slime){
        slime.render(ctx, canvas);
      });

      this.ball.render(ctx, canvas);
    }

  }


  class Slime {
    game: Game;
    radius: number;
    color: string;
    x: number;
    y: number;
    velocityX: number;
    velocityY: number;
    leftLimit: number;
    rightLimit: number;

    constructor(radius: number,
                color: string,
                leftLimit: number,
                rightLimit: number,
                game: Game) {
      this.radius = radius;
      this.color = color;
      this.leftLimit = leftLimit;
      this.rightLimit = rightLimit;
      this.game = game;
    }

    render(ctx: CanvasRenderingContext2D, canvas:HTMLCanvasElement) {
        let xPix      = this.x * PIXELS_PER_UNIT;
        let yPix      = COURT_Y - (this.y * PIXELS_PER_UNIT);

        let radiusPix = this.radius * PIXELS_PER_UNIT;
        ctx.fillStyle = this.color;
        ctx.beginPath();
        ctx.arc(xPix, yPix, radiusPix, Math.PI, 2*Math.PI);
        ctx.fill();
    }

    update() {
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
  }


  class Ball {
    game: Game;
    radius: number;
    color: string;
    x: number;
    y: number;
    velocityX: number;
    velocityY: number;

    constructor(radius: number,
                color: string,
                game: Game) {
      this.radius = radius;
      this.color = color;
      this.game = game;
    }

    render(ctx: CanvasRenderingContext2D, canvas:HTMLCanvasElement) {
      const xPix   = this.x * PIXELS_PER_UNIT;
      const yPix   = COURT_Y - (this.y * PIXELS_PER_UNIT);

      const radiusPix = this.radius * PIXELS_PER_UNIT + 2;
      ctx.fillStyle = this.color;
      ctx.beginPath();
      ctx.arc(xPix, yPix, radiusPix, 0, 2*Math.PI);
      ctx.fill();
    }

    update() {
      this.x += this.velocityX;
      this.y += this.velocityY;
      this.velocityY += -.5; // gravity
      if(this.velocityY < -MAX_VELOCITY_Y) {
        this.velocityY = -MAX_VELOCITY_Y;
      }
      
      this.game.slimes.forEach(slime => {this.collideSlime(slime);});
      
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
          this.game.initRound(true);
        } else {
          this.game.initRound(false);
        }
      }
    }

    collideSlime(slime: Slime) {
      const dx = this.x - slime.x;
      const dy = this.y - slime.y;
      const dist = Math.sqrt(dx * dx + dy * dy);

      const dVelocityX = this.velocityX - slime.velocityX;
      const dVelocityY = this.velocityY - slime.velocityY;
      if(dy > 0 && dist < this.radius + slime.radius) {
        const oldBall = {x: this.x,
                        y: this.y,
                        velocityX: this.velocityX,
                        velocityY: this.velocityY};
        this.x = slime.x + (slime.radius + this.radius) * dx / dist;
        this.y = slime.y + (slime.radius + this.radius) * dy / dist;
        
        const something = (dx * dVelocityX + dy * dVelocityY) / dist;
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
  }
}

function main(){
  NetworkGame.initializeGame();
}