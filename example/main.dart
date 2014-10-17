import 'dart:io' show Directory;
import 'package:simple_dart_api/simple_dart_api.dart';

// Import all the controllers from your API to be executed by the Simple Dart API
import 'Controllers/ControllersLibrary.dart';
import 'Utility/MyMiddleware.dart';

main() {
  var headers = {'Access-Control-Allow-Origin': '*'};
  var router = new SimpleDartApi(Directory.current.path + "/Routes/", defaultHeaders: headers);
  router.middleware = new MyMiddleware();
  router.launch("127.0.0.1", 8001);
}