import 'dart:io';
import 'dart:convert';

const NUM_PLAYERS = 2;

List<WebSocket> sockets = new List<WebSocket>();
int playerId = 0;

void handleWebSocket(WebSocket webSocket) {
  webSocket.map(JSON.decode).listen((json) {
    print(json);
    String type = json["type"];
    switch (type) {
      case "update":
        var updateMessage = {
          "type": "update",
          "frame": json["frame"],
          "playerId": json["playerId"],
          "playerInput": json["playerInput"]
        };
        for (var socket in sockets) {
          socket.add(JSON.encode(updateMessage));
        }
        webSocket.add(JSON.encode(updateMessage));
    }
  });
}

main() async {
  HttpServer server =
      await HttpServer.bind(InternetAddress.ANY_IP_V4, 8018);
  print('listening on localhost, port ${server.port}');

  await for (HttpRequest request in server) {
    var webSocket = await WebSocketTransformer.upgrade(request);
    if(playerId < NUM_PLAYERS){
      sockets.add(webSocket);

      var initMessage = {"type": "init", "playerId": playerId};
      webSocket.add(JSON.encode(initMessage));
      print("Player $playerId connected.");

      handleWebSocket(webSocket);

      playerId++;
      if (playerId == NUM_PLAYERS) {
        var startMessage = {"type": "start"};
        print("Starting game...");
        for(var socket in sockets){
          socket.add(JSON.encode(startMessage));
        }
      }
    } else {
      webSocket.addError("Error: game is full");
    }
  }
}
