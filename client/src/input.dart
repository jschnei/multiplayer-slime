import 'dart:collection';
import 'dart:convert';

import 'consts.dart';

enum Input { Left, Up, Right, Down }
Map<Input, int> DEFAULT_P1_MAPPING = {
  Input.Left: 37,   // LEFT ARROW
  Input.Up: 38,     // UP ARROW
  Input.Right: 39,  // RIGHT ARROW
  Input.Down: 40    // DOWN ARROW
};

Map<Input, int> DEFAULT_P2_MAPPING = {
  Input.Left: 65,   // A
  Input.Up: 87,     // W
  Input.Right: 68,  // D
  Input.Down: 83    // S
};

class LocalPlayer {
  int id;
  Map<Input, int> keyMapping;

  LocalPlayer(this.id, this.keyMapping);

  PlayerInput getPlayerInput(Map<int, bool> keyboardState){
    var output = new PlayerInput();
    for(var input in Input.values){
      output[input] = keyboardState[keyMapping[input]];
    }
    return output;
  }
}

class InputBuffer extends MapBase<int, FrameInput> {
  final Map<int, FrameInput> _base;

  InputBuffer(buffer) : _base = new Map<int, FrameInput>() {
    for(var frame=0;frame<buffer;frame++){
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
