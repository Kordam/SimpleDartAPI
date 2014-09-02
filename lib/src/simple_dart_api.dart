part of SimpleDartApi;

class SimpleDartApi {

  String                      _routingDir = null;
  Map<String, InstanceMirror> _classes = {};
  Log.Logger                  _logger = new Log.Logger("Routeur");
  List<Route>                 _routes = new List<Route>();  
  
  /**
   * Router's contructor
   * Take the path to the routes directory as pathToRoot
   */
  SimpleDartApi (String pathToRoute) {
    _routingDir = pathToRoute;
    final logDir = new Directory(Directory.current.path + '/logs/');
    logDir.exists().then((isThere) {
      if (!isThere)
        new Directory(Directory.current.path + '/logs/').create(recursive: true);
    });
    Log.Logger.root.level = Log.Level.ALL;
    Log.Logger.root.onRecord.listen((Log.LogRecord rec) {
      if (rec.level == Log.Level.INFO) {
        new File (Directory.current.path + "/logs/info.log").writeAsString('${rec.message}\r\n', mode: FileMode.APPEND);
      } else {
        new File (Directory.current.path + "/logs/warning.log").writeAsString('${rec.message}\r\n', mode: FileMode.APPEND);
      }
    });
    SplayTreeMap<String, Map> versions = _getVersion();
    _initRoutes(versions);
  }

  /**
   * Gets the routing configuration files, concatenated their contents and treat them
   * using their parent directory as a version
   */
  SplayTreeMap<String, Map>  _getVersion() {
    SplayTreeMap<String, Map>   versions = new SplayTreeMap<String, Map>();
    String version = "";
    String roads = "";
    new Directory(_routingDir).listSync(recursive: true, followLinks: false)
    .forEach((FileSystemEntity entity) {
      if (entity is Link) {
        return;  
      }
      if(entity.path.contains(".yaml")) {
        roads += new File (entity.path).readAsStringSync();
      } else {
        if (version != "")
          versions[version] = loadYaml(roads);
        roads = "";
        version = entity.path.split("/").last;
      }
    });
    versions[version] = loadYaml(roads);
    return versions;
  }

  /**
   * Goes through all the roads of the files and initialize them with the apropriate version.
   */
  void _initRoutes(SplayTreeMap<String, Map>  versions) {
    for(var i = 0; i < versions.values.length; i++) {
      var version = versions.keys.elementAt(i);
      var previous_routes = null;
      if (i != 0) {
        // Get the previous version of the API
        previous_routes = versions.values.elementAt(i - 1);
      }
      var current_roads = versions.values.elementAt(i);
      if (current_roads != null) {
        current_roads.forEach((String routeName, Map info) {
          Route route = _getRouteInfo(version, routeName, info);
          _createRoute(route);
        });
      }

      if (current_roads != null && previous_routes != null) {
        previous_routes.forEach((String routeName, Map info) {
          if (!current_roads.containsKey(routeName)) {
            Route route = _getRouteInfo(version, routeName, info);
            _createRoute(route);
          }
        });
      }
    }
  }

  /**
   * Get the information from a version of a route
   */
  Route _getRouteInfo(String version, String routeName, Map info) {
      Route route = new Route(version);
      route.url = new UrlPattern("/" + version  + info["route"]);
      if (info["needConnection"] == true) {
        route.needConnection = true;
      }
      route.name = routeName;
      route.methods = ((info.containsKey("method")) ? info["method"].replaceAll(" ", '').split("|") : [""]);
      List<String> functions = (info["action"] as String).split(":");
      if (!_classes.containsKey(functions[0]))
            _classes[functions[0]]  = _createClass(functions[0]);
      route.classe = _classes[functions[0]];
      route.function = functions[1];
      
      route.handler = (HttpRequest req) {
        List args = new List();
        args.add(req);
        args.addAll(route.url.parse(req.uri.path));
        route.classe.invoke(new Symbol(route.function), args).reflectee;
        req.response.close();
      };
      
      return route;
  }


  /**
   * Creates the route by [url] and crete them for each methods of the [route]
   */
  void _createRoute(Route route) {
    _routes.add(route);
  }

  /**
   * Creates dynamicaly a class by it's name.
   * Returns an instance of the given class
   */
  InstanceMirror _createClass(String className) {
    MirrorSystem mirrors = currentMirrorSystem();
    mirrors.libraries.values.forEach((LibraryMirror e) {
      print(e.simpleName.toString());
    });
    
    LibraryMirror lm = mirrors.libraries.values.firstWhere(
       (LibraryMirror lm) => lm.qualifiedName == new Symbol('controllers'));
      ClassMirror cm = lm.declarations[new Symbol(className + "Controller")];
      InstanceMirror im = cm.newInstance(new Symbol(''), []);
      return im;
  }
  
  /**
   *  Launches the router on the given [host] and [port]
   */
  void launch(String host, int port) {
    HttpServer.bind(host, port).then((HttpServer server) {
      _logger.log(Log.Level.INFO, "listening on ${server.address}, port ${server.port}");
      var router = new Router(server);
      for (Route route in _routes) {
        for (String method in route.methods) {
          router.serve(route.url, method: method).listen(route.handler);
        }
      }
      router.defaultStream.listen(send404);
    });
  }

}
