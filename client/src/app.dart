import 'dart:convert';
import 'dart:core';
import 'dart:html';

import 'consts.dart';
import 'input.dart';
import 'slime_volleyball.dart' as SlimeVolleyball;

abstract class GameState {
  void render(CanvasRenderingContext2D ctx, CanvasElement canvas);
  void update(FrameInput inputs);
}

GameState gameState;

CanvasElement canvas;
CanvasRenderingContext2D ctx;

num interval = 1000 / FPS;
num lastTime = new DateTime.now().millisecondsSinceEpoch;
num currentTime = 0;
int curFrame = 0;

int myId;
InputBuffer inputBuffer = new InputBuffer();
PlayerInput playerInput = new PlayerInput();

WebSocket ws;

void keyDown(KeyboardEvent e){
  if(keyMapping.containsKey(e.keyCode)){
    playerInput[keyMapping[e.keyCode]] = true;
  }
}

void keyUp(KeyboardEvent e){
  if(keyMapping.containsKey(e.keyCode)){
    playerInput[keyMapping[e.keyCode]] = false;
  }
}

void emitKeys(){
  var message = {"type": "update",
                 "frame": curFrame,
                 "playerId": myId,
                 "playerInput": playerInput.toJSON()};
  ws.send(JSON.encode(message));

  inputBuffer[curFrame + BUFFER][myId] = new PlayerInput.from(playerInput);
}

void loop(num frames) {
  window.requestAnimationFrame(loop);

  currentTime = new DateTime.now().millisecondsSinceEpoch;
  var delta = currentTime - lastTime;

  if (delta > interval) {
    if (inputBuffer[curFrame].hasInputs()) {
      gameState.update(inputBuffer[curFrame]);
      gameState.render(ctx, canvas);
      emitKeys();

      lastTime = currentTime;
      curFrame += 1;
    } else {
      print("Waiting for input for frame $curFrame");
    }
  }
}

void main() {
  var gameDiv = querySelector('#game');
  canvas = new CanvasElement();
  canvas.width = 730;
  canvas.height = 365;
  gameDiv.append(canvas);

  window.onKeyDown.listen(keyDown);
  window.onKeyUp.listen(keyUp);

  ctx = canvas.getContext("2d");

  gameState = new SlimeVolleyball.Game();

  ws = new WebSocket('ws://${Uri.base.host}:8018/');

  ws.onMessage.listen((MessageEvent e){
    var data = JSON.decode(e.data);
    String type = data["type"];
    
    switch(type){
      case "init":
        myId = data["playerId"];
        break;

      case "start":
        loop(0);
        break;

      case "update":
        inputBuffer[data["frame"] + BUFFER][data["playerId"]] = new PlayerInput.fromJSON(data["playerInput"]);
        break;
    }
  });
}

