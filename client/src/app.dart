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

void startGame({bool create}){
  hide(querySelector('#options'));
  hide(querySelector("#errors"));
  show(querySelector('#game'));

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
    int bufferInputValue = -1;
    
    if(create){
      InputElement bufferInput = querySelector("#buffer");

      try {
        bufferInputValue = int.parse(bufferInput.value);

        if(bufferInputValue <=0){
          throw new Error();
        }
      } catch(e) {
        print(e.toString());
        displayError("Error: invalid buffer value");
        return;
      }

    }

    InputElement roomInput = querySelector(create ? "#room_create" : "#room_join");
    room = roomInput.value.trim().toLowerCase();

    try{
      ws = new WebSocket('ws://${Uri.base.host}:${SERVER_PORT}/');

      ws.onError.listen((MessageEvent e){
        displayError("Error: unable to reach server");
      });

      ws.onOpen.listen((MessageEvent e){
        var joinMessage = {"type": create ? "createRoom" : "joinRoom",
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
                            "room": room,
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
            displayError(data["message"]);
            break;
        }
      });

    } catch(e) {
      print(e);
      displayError("Error: unable to reach server");
    }
  }
}

void main() {
  // hack so #errors doesn't flicker in before page loads
//  querySelector('#errors').hidden = true;
  
  //hide(querySelector("#errors"));

  querySelector('#local').onClick.listen((e){
    isLocal = true;
    startGame();
  });

  querySelector('#network_create').onClick.listen((e){
    isLocal = false;
    startGame(create: true);
  });
  
  querySelector('#network_join').onClick.listen((e){
    isLocal = false;
    startGame(create: false);
  });
}

void displayError(error){
  print(error);
  Element errorBox = querySelector("#errors");
  errorBox.text = error;

  show(querySelector("#errors"));
  show(querySelector("#options"));

  querySelector("#game").innerHtml = "";
  hide(querySelector("#game"));
}

// workaround, since .hidden seems to act strangely
void hide(Element el){
  el.style.display = 'none';
}

void show(Element el){
  el.style.display = '';
}