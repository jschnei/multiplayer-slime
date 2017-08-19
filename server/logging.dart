import "dart:io";

class Logger {
  File logFile;
  IOSink sink;
  
  Logger(String fileName){
    logFile = new File(fileName);
    sink = logFile.openWrite(mode: FileMode.APPEND);
  }

  void log(String message, [String tag = "log"]){
    String timestamp = new DateTime.now().toString();

    sink.writeln('($timestamp) [$tag] $message');
  }

  void close() {
    sink.close();
  }
}