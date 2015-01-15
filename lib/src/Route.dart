part of SimpleDartApi;

class Route {
  String name = "";
  List<String> methods = [];
  UrlPattern url;
  String version = "";
  bool needConnection = false;
  InstanceMirror classe;
  String function = "";
  Function handler;
  bool options = false;

  Route(this.version, {String name, String methods, String url, InstanceMirror classe}) {
  }
}