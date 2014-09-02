import 'dart:io' show Directory;
import 'dart:mirrors';
import 'package:simple_dart_api/simple_dart_api.dart';
import 'controllers/ControllersLibrary.dart';

main() {
  
/*  MirrorSystem mirrors = currentMirrorSystem();
  mirrors.libraries.values.forEach((LibraryMirror e) {
    print(e.simpleName.toString());
  });
*/
  var router = new SimpleDartApi(Directory.current.path + "/Routes/");
  router.launch("127.0.0.1", 8001);
}