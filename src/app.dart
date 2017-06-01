import 'dart:collection';
import 'dart:html';

// import 'package:socket_io_client/socket_io_client.dart' as IO;

const num FPS = 50;

const GAME_WIDTH = 730;
const GAME_HEIGHT = GAME_WIDTH / 2;
const PIXELS_PER_UNIT = GAME_WIDTH / 1000;
const COURT_Y = 4 * GAME_HEIGHT / 5;
const SLIME_RADIUS = 50;
const BALL_RADIUS = 15;

const MAX_VELOCITY_X = 15;
const MAX_VELOCITY_Y = 11;

const NUM_PLAYERS = 2;
const BUFFER = 3;

abstract class GameState {
  void render(CanvasRenderingContext ctx, CanvasElement canvas);
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

enum Input { Left, Up, Right, Down }
Map<int, Input> keyMapping = {
  37: Input.Left,
  38: Input.Up,
  39: Input.Right,
  40: Input.Down
};

class InputBuffer extends ListBase<FrameInput> {
  final List<FrameInput> _base;

  InputBuffer() : _base = new List<FrameInput>(BUFFER + 5);

  FrameInput operator [](int index) => _base[index];
  void operator []=(int index, FrameInput frameInput) {
    _base[index] = frameInput;
  }

  int get length => _base.length;
  void set length(int newLength) {
    _base.length = newLength;
  }
}

class FrameInput extends ListBase<PlayerInput> {
  final List<PlayerInput> _base;
  final int frameNumber;

  FrameInput({this.frameNumber}) : _base = new List<PlayerInput>(NUM_PLAYERS);

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

void loop(num frames) {
  window.requestAnimationFrame(loop);

  currentTime = new DateTime.now().millisecondsSinceEpoch;
  var delta = currentTime - lastTime;

  if (delta > interval) {
    if (haveInputs(curFrame)) {} else {
      print("Waiting for input for frame $curFrame");
    }
  }
}

void main() {
  var gameDiv = querySelector('game');
  canvas = new CanvasElement();
  canvas.width = 730;
  canvas.height = 365;
  gameDiv.append(canvas);

  canvas.onKeyDown.listen(keyDown);
  canvas.onKeyUp.listen(keyUp);

  ctx = canvas.getContext("2d");
}
