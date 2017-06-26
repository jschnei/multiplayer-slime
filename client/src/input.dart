import 'dart:collection';
import 'dart:convert';

import 'consts.dart';

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
