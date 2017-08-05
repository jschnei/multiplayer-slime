import 'dart:io';
import 'dart:convert';

const NUM_PLAYERS = 2;
const DEFAULT_BUFFER = 3;

List<WebSocket> sockets = new List<WebSocket>();
int playerId = 0;
int buffer = 3;

void broadcastMessage(dynamic message){
  for (var socket in sockets){
    socket.add(JSON.encode(message));
  }
}

void handleWebSocket(WebSocket webSocket) {
  webSocket.map(JSON.decode).listen((json) {
    String type = json["type"];
    switch (type) {
      case "update":
        var message = {
          "type": "update",
          "frame": json["frame"],
          "playerId": json["playerId"],
          "playerInput": json["playerInput"]
        };
        broadcastMessage(message);
        break;
      case "setBuffer":
        buffer = json["buffer"];
        print("set buffer to $buffer");
        break;
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
      if(playerId < NUM_PLAYERS){
        sockets.add(webSocket);

        var initMessage = {"type": "init", "playerId": playerId};
        webSocket.add(JSON.encode(initMessage));
        print("Player $playerId connected.");

        handleWebSocket(webSocket);

        playerId++;
        if (playerId == NUM_PLAYERS) {
          var startMessage = {"type": "start", "buffer": buffer};
          print("Starting game...");
          broadcastMessage(startMessage);
        }
      } else {
        print("Error: game is full");
        webSocket.addError("Error: game is full");
      }
    } on WebSocketException{
      print("Error: must connect via websocket protocol");
    } catch(e){
      print(e);
    }
  }
}
