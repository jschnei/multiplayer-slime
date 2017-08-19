import 'dart:io';
import 'dart:convert';

import 'logging.dart';

const NUM_PLAYERS = 2;
const DEFAULT_BUFFER = 3;

const LOG_FILE = "logs/server.log";
Logger logger = new Logger(LOG_FILE);

Map<String, Room> rooms = new Map<String, Room>();

void sendError(socket, message) {
  logger.log(message, "error");
  var errorMessage = {"type": "error", "message": message};
  socket.add(JSON.encode(errorMessage));
}

enum RoomState { OPEN, GAME_RUNNING, CLOSED }

class Room {
  String name;
  List<WebSocket> players;
  int buffer = DEFAULT_BUFFER;
  RoomState state = RoomState.OPEN;

  Room(this.name, {this.buffer}) : players = new List<WebSocket>();

  void broadcastMessage(dynamic message) {
    for (var socket in players) {
      socket.add(JSON.encode(message));
    }
  }

  void addPlayer(WebSocket socket) {
    if (players.length < NUM_PLAYERS) {
      int playerId = players.length;

      // add player to room
      players.add(socket);
      socket.done.then((socket) {
        destroyRoom();
      });

      var initMessage = {"type": "init", "playerId": playerId};
      socket.add(JSON.encode(initMessage));
      logger.log("Player $playerId connected.");

      if (players.length == NUM_PLAYERS) {
        startGame();
      }
    } else {
      // send error
      sendError(socket, "room $name is full");
    }
  }

  void startGame() {
    var startMessage = {"type": "start", "buffer": buffer};
    logger.log("Starting game in room $name...");
    broadcastMessage(startMessage);
    state = RoomState.GAME_RUNNING;
  }

  void destroyRoom() {
    if (state == RoomState.CLOSED) return; // already being destroyed

    logger.log("Closing room $name");
    state = RoomState.CLOSED;

    for (var socket in players) {
      if (socket.readyState == WebSocket.OPEN) {
        var endMessage = {
          "type": "error",
          "message": "A player has disconnected."
        };
        socket.add(JSON.encode(endMessage));
      }

      socket.close();
    }

    // remove from rooms list
    rooms[name] = null;
  }
}

void handleWebSocket(WebSocket webSocket) {
  webSocket.map(JSON.decode).listen((json) {
    try {
      String type = json["type"];
      String roomName = json["room"];
      Room room = rooms[roomName];

      if (type != "createRoom" && room == null) {
        sendError(webSocket, "no room with name $roomName");
      } else {
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
          case "createRoom":
            if (room == null) {
              logger.log("Creating new room $roomName");
              rooms[roomName] = new Room(roomName);
              room = rooms[roomName];

              room.addPlayer(webSocket);
            } else {
              sendError(webSocket, "room $roomName already exists");
            }
            break;
          case "joinRoom":
            room.addPlayer(webSocket);
            break;
          case "setBuffer":
            room.buffer = json["buffer"];
            logger.log("Set buffer for $roomName to ${room.buffer}");
            break;
          case "error":
            logger.log(json["message"]);
            break;
        }
      }
    } catch (e) {
      logger.log(e.toString(), 'error');
    }
  });
}

main() async {
  HttpServer server = await HttpServer.bind(InternetAddress.ANY_IP_V4, 8018);
  logger.log('Listening on 0.0.0.0, port ${server.port}', 'init');

  await for (HttpRequest request in server) {
    try {
      logger.log(request.connectionInfo.remoteAddress.toString(), "ip");
      var webSocket = await WebSocketTransformer.upgrade(request);
      handleWebSocket(webSocket);
    } on WebSocketException {
      logger.log("must connect via websocket protocol", 'error');
    } catch (e) {
      logger.log(e.toString(), 'error');
    }
  }
}
