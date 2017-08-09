import 'dart:io';
import 'dart:convert';

const NUM_PLAYERS = 2;
const DEFAULT_BUFFER = 3;

class Room {
  String name;
  List<WebSocket> players;
  int buffer = DEFAULT_BUFFER;

  Room(this.name, {this.buffer}): players = new List<WebSocket>();

  void broadcastMessage(dynamic message){
    for (var socket in players){
      socket.add(JSON.encode(message));
    }
  }

  void addPlayer(WebSocket socket){
    if(players.length < NUM_PLAYERS){
      int playerId = players.length;

      // add player to room
      players.add(socket);

      var initMessage = {"type": "init", "playerId": playerId};
      socket.add(JSON.encode(initMessage));
      print("Player $playerId connected.");
    }else{
      // send error
      print("Error: room $name is full");
      var errorMessage = {"type": "error", "message": "Error: room $name is full"};
      socket.add(JSON.encode(errorMessage));
    }
  }

  void startGame(){
      var startMessage = {"type": "start", "buffer": buffer};
      print("Starting game in room $name...");
      broadcastMessage(startMessage);
  }

  int get playerId => players.length;
}

Map<String, Room> rooms = new Map<String, Room>();

void handleWebSocket(WebSocket webSocket) {
  webSocket.map(JSON.decode).listen((json) {
    try {
      String type = json["type"];
      String roomName = json["room"];
      Room room = rooms[roomName];
      switch (type) {
        case "update":
          var message = {
            "type": "update",
            "frame": json["frame"],
            "playerId": json["playerId"],
            "playerInput": json["playerInput"]
          };
          room.broadcastMessage(message);
          break;
        case "joinRoom":
          if(room == null){
            print("Creating new room $roomName");
            rooms[roomName] = new Room(roomName);
            room = rooms[roomName];
          }

          room.addPlayer(webSocket);
          if(room.players.length == NUM_PLAYERS){
            room.startGame();
          }
          
          break;  
        case "setBuffer":
          room.buffer = json["buffer"];
          print("Set buffer for $roomName to ${room.buffer}");
          break;
      } 
    } catch(e){
      print(e);
    }
    
  });
}

main() async {
  HttpServer server =
      await HttpServer.bind(InternetAddress.ANY_IP_V4, 8018);
  print('listening on 0.0.0.0, port ${server.port}');

  await for (HttpRequest request in server) {
    try{
      var webSocket = await WebSocketTransformer.upgrade(request);
      handleWebSocket(webSocket);
    } on WebSocketException{
      print("Error: must connect via websocket protocol");
    } catch(e){
      print(e);
    }
  }
}
