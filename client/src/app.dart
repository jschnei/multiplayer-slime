import 'dart:collection';
import 'dart:convert';
import 'dart:core';
import 'dart:html';

import 'consts.dart';
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

enum Input { Left, Up, Right, Down }
Map<int, Input> keyMapping = {
  37: Input.Left,
  38: Input.Up,
  39: Input.Right,
  40: Input.Down
};

class InputBuffer extends MapBase<int, FrameInput> {
  final Map<int, FrameInput> _base;

  InputBuffer() : _base = new Map<int, FrameInput>() {
    for(var frame=0;frame<BUFFER;frame++){
      _base[frame] = new FrameInput.emptyFrame();
    }
  }

  FrameInput operator [](int frameNumber){
    if(!_base.containsKey(frameNumber)){
      _base[frameNumber] = new FrameInput();
    }
    return _base[frameNumber];
  }
  void operator []=(int frameNumber, FrameInput frameInput) {
    _base[frameNumber] = frameInput;
  }
  Iterable<int> get keys => _base.keys;
  void clear() {
    _base.clear();
  }

  FrameInput remove(int frameNumber) => _base.remove(frameNumber);
}

class FrameInput extends ListBase<PlayerInput> {
  final List<PlayerInput> _base;

  FrameInput() : _base = new List<PlayerInput>(NUM_PLAYERS);
  FrameInput.emptyFrame(): _base = new List<PlayerInput>(NUM_PLAYERS){
    for(var playerId = 0; playerId < NUM_PLAYERS; playerId++){
      _base[playerId] = new PlayerInput();
    }
  }

  bool hasInputs(){
    return _base.every((input) => (input!=null));
  }

  PlayerInput operator [](int index) => _base[index];
  void operator []=(int index, PlayerInput playerInput) {
    _base[index] = playerInput;
  }

  int get length => _base.length;
  void set length(int newLength) {
    _base.length = newLength;
  }
}

class PlayerInput extends MapBase<Input, bool> {
  final Map<Input, bool> _base;

  PlayerInput() : _base = new Map<Input, bool>() {
    for (var input in Input.values) {
      _base[input] = false;
    }
  }
  PlayerInput.from(PlayerInput other) : _base = new Map.from(other._base);
  PlayerInput.fromJSON(String json) : _base = new Map.fromIterables(Input.values, (JSON.decode(json)));

  String toJSON() => JSON.encode(Input.values.map((input) => _base[input]).toList());

  bool operator [](Input input) => _base[input];
  void operator []=(Input input, bool b) {
    _base[input] = b;
  }

  Iterable<Input> get keys => _base.keys;
  void clear() {
    _base.clear();
  }

  bool remove(Input input) => _base.remove(input);
}

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

