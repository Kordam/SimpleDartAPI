part of router;

class Route {
  String name = "";
  List<String> methods = [];
  String url = "";
  String version = "";
  bool needConnection = false;
  InstanceMirror classe;
  String function = "";

  Route(this.version, {String name, String methods, String url, InstanceMirror classe}) {

  }
}