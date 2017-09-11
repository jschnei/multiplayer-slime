import 'dart:html';
import 'dart:math' as Math;

import 'app.dart';
import 'input.dart';
import 'consts.dart';

class Game implements AbstractGame {
  ScoreBoard scoreBoard;
  List<Slime> slimes;
  Ball ball;
  

  Game(){
    GameObject.game = this;

    slimes = [new Slime(SLIME_RADIUS, SLIME_1_COLOR, 0, 495),
              new Slime(SLIME_RADIUS, SLIME_2_COLOR, 505, 1000)];
    ball = new Ball(BALL_RADIUS, BALL_COLOR);
    scoreBoard = new ScoreBoard();

    initRound(true);
  }

  void update(FrameInput frameInput){
    for(int id=0;id<NUM_PLAYERS;id++){
      var keys = frameInput[id];
      var slime = slimes[id];

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

    for(var slime in slimes){
      slime.update();
    }

    this.ball.update();
  }

  void render(CanvasRenderingContext2D ctx, CanvasElement canvas){
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const courtHeight = GAME_HEIGHT/5;
    ctx.fillStyle='#0077ff';
    ctx.fillRect(0, 0, GAME_WIDTH, GAME_HEIGHT-courtHeight); // draw sky
    ctx.fillStyle='#ca6';
    ctx.fillRect(0, GAME_HEIGHT-courtHeight, GAME_WIDTH, courtHeight); // draw ground
    ctx.fillStyle='#fff';
    ctx.fillRect(GAME_WIDTH/2-2,7*GAME_HEIGHT/10,4,GAME_HEIGHT/10+5); // draw net

    scoreBoard.render(ctx, canvas);

    for(var slime in slimes){
      slime.render(ctx, canvas);
    }

    ball.render(ctx, canvas);
  }

  // player = true for left, false for right
  void score(bool player){
    if(player){
      scoreBoard.player1Score++;
      scoreBoard.player2Score--;
    }else{
      scoreBoard.player1Score--;
      scoreBoard.player2Score++;
    }
    initRound(player);
  }

  void initRound(bool server){
    ball.x = server ? 200 : 800;
    ball.y = 200;
    ball.velocityX = 0;
    ball.velocityY = 0;

    slimes[0].x = 200;
    slimes[0].y = 0;
    slimes[0].velocityX = 0;
    slimes[0].velocityY = 0;

    slimes[1].x = 800;
    slimes[1].y = 0;
    slimes[1].velocityX = 0;
    slimes[1].velocityY = 0;
  }

}

class ScoreBoard{
  int winBy;
  int player1Score;
  int player2Score;

  ScoreBoard({this.winBy: DEFAULT_WIN_BY}){
    player1Score = winBy;
    player2Score = winBy;
  }

  void render(CanvasRenderingContext2D ctx, 
              CanvasElement canvas){
    
    // render player 1's score balls
    for(var i=0;i<player1Score;i++){
      renderBall(ctx, 
                 canvas, 
                 SCOREBOARD_MARGIN+i*(2*SCOREBOARD_RADII + SCOREBOARD_PADDING),
                 SCOREBOARD_HEIGHT,
                 SLIME_1_COLOR);
    }

    for(var i=0;i<player2Score;i++){
      renderBall(ctx, 
                 canvas, 
                 GAME_WIDTH-(SCOREBOARD_MARGIN+i*(2*SCOREBOARD_RADII + SCOREBOARD_PADDING))-SCOREBOARD_RADII,
                 SCOREBOARD_HEIGHT,
                 SLIME_2_COLOR);
    }
  }

  void renderBall(CanvasRenderingContext2D ctx,
                  CanvasElement canvas,
                  int x,
                  int y,
                  String color){
    final xPix = x;
    final yPix = y;
    final radiusPix = SCOREBOARD_RADII;

    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(xPix, yPix, radiusPix, 0, 2*Math.PI);
    ctx.fill();
  }

}

abstract class GameObject {
  static Game game;

  num x;
  num y;
  num velocityX;
  num velocityY;

  void render(CanvasRenderingContext2D ctx, CanvasElement canvas);
  void update();
}

class Slime extends GameObject {
  num radius;
  String color;
  
  num leftBoundary;
  num rightBoundary;

  Slime(this.radius, this.color, this.leftBoundary, this.rightBoundary);

  void render(CanvasRenderingContext2D ctx,
              CanvasElement canvas){
    final xPix = x * PIXELS_PER_UNIT;
    final yPix = COURT_Y - y * PIXELS_PER_UNIT;

    final radiusPix = radius * PIXELS_PER_UNIT;

    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(xPix, yPix, radiusPix, Math.PI, 2*Math.PI);
    ctx.fill();
  }

  void update(){
      if(velocityX != 0) {
        x += velocityX;
        if(x - radius < leftBoundary) {
          x = leftBoundary + radius;
        } else if(x + radius > rightBoundary) {
          x = rightBoundary - radius;
        }
      }
      if(velocityY != 0 || y > 0) {
        y += velocityY;
        velocityY -= 1.2;
        if(y < 0) {
          y = 0;
          velocityY = 0;
        }
      }
  }
}

class Ball extends GameObject {
  num radius;
  String color;

  Ball(this.radius, this.color);

  render(CanvasRenderingContext2D ctx, CanvasElement canvas) {
    final xPix = x * PIXELS_PER_UNIT;
    final yPix = COURT_Y - (y * PIXELS_PER_UNIT);
    final radiusPix = radius * PIXELS_PER_UNIT + 2;

    ctx.fillStyle = color;
    ctx.beginPath();
    ctx.arc(xPix, yPix, radiusPix, 0, 2*Math.PI);
    ctx.fill();
  }

  update() {
    x += velocityX;
    y += velocityY;

    velocityY -= 0.5;
    if(velocityY < -MAX_VELOCITY_Y){
      velocityY = -MAX_VELOCITY_Y;
    }

    for(var slime in GameObject.game.slimes){
      collideSlime(slime);
    }

    // detect wall collisions
    if(x - radius < 0){
      x = radius;
      velocityX = -velocityX;
    }else if(x + radius > 1000) {
      x = 1000 - radius;
      velocityX = -velocityX;
    }

    // detect net collisions
    if (x > 480 && x < 520 && y < 70) {
      // bounces off top of net
      if (velocityY < 0 && y > 65) {
        velocityY *= -1;
        y = 65;
      } else if (x < 500) { // hits side of net
        x = 480;
        velocityX = velocityX >= 0 ? -velocityX : velocityX;
      } else {
        x = 520;
        velocityX = velocityX <= 0 ? -velocityX : velocityX;
      }
    }

    if(y < 0){
      if(x > 500){
        GameObject.game.score(true);
      } else {
        GameObject.game.score(false);
      }
    }

  }

  collideSlime(Slime slime){
    final dx = x - slime.x;
    final dy = y - slime.y;
    final dist = Math.sqrt(dx * dx + dy * dy);

    final dVelocityX = velocityX - slime.velocityX;
    final dVelocityY = velocityY - slime.velocityY;
    if(dy > 0 && dist < radius + slime.radius) {
      x = slime.x + (slime.radius + radius) * dx / dist;
      y = slime.y + (slime.radius + radius) * dy / dist;
      
      final something = (dx * dVelocityX + dy * dVelocityY) / dist;
      if(something <= 0) {
        velocityX += slime.velocityX - 1.92 * dx * something / dist;
        velocityY += slime.velocityY - 1.92 * dy * something / dist;
        if(     velocityX < -MAX_VELOCITY_X) velocityX = -MAX_VELOCITY_X;
        else if(velocityX >  MAX_VELOCITY_X) velocityX =  MAX_VELOCITY_X;
        if(     velocityY < -MAX_VELOCITY_Y) velocityY = -MAX_VELOCITY_Y;
        else if(velocityY >  MAX_VELOCITY_Y) velocityY =  MAX_VELOCITY_Y;
      }
    }
  }

}