import 'dart:io';
import 'dart:convert';

const NUM_PLAYERS = 2;

Map<String, List<WebSocket>> rooms = new Map<String, List<WebSocket>>();
int buffer = 3;

void broadcastMessage(dynamic message, String room){
  for (var socket in rooms[room]){
    socket.add(JSON.encode(message));
  }
}

void handleWebSocket(WebSocket webSocket) {
  webSocket.map(JSON.decode).listen((json) {
    try {
      String type = json["type"];
      switch (type) {
        case "update":
          var message = {
            "type": "update",
            "frame": json["frame"],
            "playerId": json["playerId"],
            "playerInput": json["playerInput"]
          };
          broadcastMessage(message, json["room"]);
          break;
        case "joinRoom":
          String room = json["room"];
          if(rooms[room] == null){
            rooms[room] = new List<WebSocket>();
          }
          int playerId = rooms[room].length;
          if(playerId < NUM_PLAYERS){
            // add player to room
            rooms[room].add(webSocket);

            var initMessage = {"type": "init", "playerId": playerId};
            webSocket.add(JSON.encode(initMessage));
            print("Player $playerId connected.");
          }else{
            // send error
            print("Error: room $room is full");
            var errorMessage = {"type": "error", "message": "Error: room $room is full"};
            webSocket.add(JSON.encode(errorMessage));
          }

          if(rooms[room].length == NUM_PLAYERS){
            // start the game
            var startMessage = {"type": "start", "buffer": buffer};
            print("Starting game in room $room...");
            broadcastMessage(startMessage, room);
          }

          break;  
        case "setBuffer":
          buffer = json["buffer"];
          print("Set buffer to $buffer");
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
