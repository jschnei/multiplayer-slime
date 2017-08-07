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

bool isLocal;
String room;
int buffer = DEFAULT_BUFFER;
List<LocalPlayer> localPlayers = new List();

InputBuffer inputBuffer;
Map<int, bool> keyboardState = new Map<int, bool>();

WebSocket ws;

void keyDown(KeyboardEvent e){
  keyboardState[e.keyCode] = true;
}

void keyUp(KeyboardEvent e){
  keyboardState[e.keyCode] = false;
}

void processInput(){
  for(var player in localPlayers){
    PlayerInput playerInput = player.getPlayerInput(keyboardState);
    inputBuffer[curFrame + buffer][player.id] = playerInput;

    if(!isLocal){
      var message = {"type": "update",
                   "frame": curFrame,
                   "playerId": player.id,
                   "playerInput": playerInput.toJSON(),
                   "room": room};
      ws.send(JSON.encode(message));
    }

  }
}

void loop(num frames) {
  window.requestAnimationFrame(loop);

  currentTime = new DateTime.now().millisecondsSinceEpoch;
  var delta = currentTime - lastTime;

  if (delta > interval) {
    if (inputBuffer[curFrame].hasInputs()) {
      gameState.update(inputBuffer[curFrame]);
      gameState.render(ctx, canvas);
      processInput();

      lastTime = currentTime;
      curFrame += 1;
    } else {
      print("Waiting for input for frame $curFrame");
    }
  }
}

void startGame(){
  querySelector('#options').hidden = true;

  var gameDiv = querySelector('#game');
  canvas = new CanvasElement();
  canvas.width = 730;
  canvas.height = 365;
  gameDiv.append(canvas);

  window.onKeyDown.listen(keyDown);
  window.onKeyUp.listen(keyUp);

  ctx = canvas.getContext("2d");

  gameState = new SlimeVolleyball.Game();

  if(isLocal){
    // no need to connect to the websocket, just register local players
    localPlayers.add(new LocalPlayer(0, DEFAULT_P1_MAPPING));
    localPlayers.add(new LocalPlayer(1, DEFAULT_P2_MAPPING));

    buffer = LOCAL_BUFFER;
    inputBuffer = new InputBuffer(buffer);

    loop(0);
  }else{
    InputElement bufferInput = querySelector("#buffer");
    int bufferInputValue = -1;
    try {
      bufferInputValue = int.parse(bufferInput.value);
    } catch(e) {
      print(e);
    }

    InputElement roomInput = querySelector("#room");
    room = roomInput.value.trim().toLowerCase();

    ws = new WebSocket('ws://${Uri.base.host}:${SERVER_PORT}/');

    ws.onOpen.listen((MessageEvent e){
      var joinMessage = {"type": "joinRoom",
                    "room": room};
      ws.send(JSON.encode(joinMessage));
    });
    

    ws.onMessage.listen((MessageEvent e){
      var data = JSON.decode(e.data);
      String type = data["type"];
      
      switch(type){
        case "init":
          localPlayers.add(new LocalPlayer(data["playerId"], DEFAULT_P1_MAPPING));
          if(bufferInputValue > 0){
            var message = {"type": "setBuffer",
                           "buffer": bufferInputValue};
            ws.send(JSON.encode(message));
          }
          break;

        case "start":
          buffer = data["buffer"];
          inputBuffer = new InputBuffer(buffer);
          loop(0);
          break;

        case "update":
          inputBuffer[data["frame"] + buffer][data["playerId"]] = new PlayerInput.fromJSON(data["playerInput"]);
          break;
        
        case "error":
          print(data["message"]);
          break;
      }
    });
  }
}

void main() {
  
  querySelector('#local').onClick.listen((e){
    isLocal = true;
    startGame();
  });

  querySelector('#network').onClick.listen((e){
    isLocal = false;
    startGame();
  });
  
}

