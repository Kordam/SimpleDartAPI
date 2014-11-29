part of SimpleDartApi;

class SimpleDartApi {

  String                      _libraryName;
  String                      _routingDir = null;
  Map<String, String>         _defaultHeaders = new Map<String, String>();
  Map<String, InstanceMirror> _classes = {};
  Log.Logger                  _logger = new Log.Logger("Routeur");
  List<Route>                 _routes = new List<Route>();
  List<MiddlewareController>  middlewares = new List<MiddlewareController>();
  HttpServer                  httpServer = null;

  /**
   * Router's contructor
   * Take the path to the routes directory as pathToRoot
   */
  SimpleDartApi (String pathToRoute, {libraryName: "controllers", defaultHeaders}) {
    _routingDir = pathToRoute;
    _libraryName = libraryName;
    if (defaultHeaders != null && defaultHeaders is Map<String, String>)
      _defaultHeaders = defaultHeaders;
    initLogger();
    SplayTreeMap<String, Map> versions = _getVersion();
    _initRoutes(versions);
  }

  void initLogger() {
    final logDir = new Directory(Directory.current.path + '/logs/');
    logDir.exists().then((isThere) {
      if (isThere == false)
        new Directory(Directory.current.path + '/logs/').createSync(recursive: true);
    });
    Log.Logger.root.level = Log.Level.ALL;
    Log.Logger.root.onRecord.listen((Log.LogRecord rec) {
      if (rec.level == Log.Level.INFO) {
        new File (Directory.current.path + "/logs/info.log").writeAsString('${rec.message}\r\n', mode: FileMode.APPEND);
      } else {
        new File (Directory.current.path + "/logs/warning.log").writeAsString('${rec.message}\r\n', mode: FileMode.APPEND);
      }
    });
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
          _routes.add(route);
        });
      }

      if (current_roads != null && previous_routes != null) {
        previous_routes.forEach((String routeName, Map info) {
          if (!current_roads.containsKey(routeName)) {
            Route route = _getRouteInfo(version, routeName, info);
            _routes.add(route);
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
      if (info.containsKey("options")) {
        route.options = ((info["options"] is bool && info["options"] == true) || (info["options"] is String && info["options"] == "true")) ? true : false;
      }
      route.handler = (HttpRequest req) {
        Future response = _executeAllMiddlewares(req, route)
          .then( (_) {
            List args = new List();
            args.add(req);
            args.addAll(route.url.parse(req.uri.path));
            var res = route.classe.invoke(new Symbol(route.function), args).reflectee;
            _getReponse(res, req);
          }).catchError( (res) {
            print(res);
            _getReponse(res, req);
          });
      };
      return route;
  }

  Future _executeAllMiddlewares(HttpRequest req, Route route) {
    Completer completer = new Completer();
    Future fut = Future.wait([]);

    for (var i = 0; i < middlewares.length; ++i)
      fut = fut.then( (_) { middlewares[i].execute(req, route); } );

    return fut;
  }

  /**
   * Get the response sent from the controller
   */
  void _getReponse(response, HttpRequest req) {
    if (response is Response) {
      _sendResponse(response,req);
    } else if (response is Future<Response>) {
      (response as Future<Response>).then((rep) {
        if (response is Response) {
          _sendResponse(rep, req);
        } else {
          _sendResponse(new Response(rep), req);
        }
      });
    } else {
      _sendResponse(new Response(response), req);
    }
  }

  /**
   * Send the response
   */
  void _sendResponse(Response response, HttpRequest req) {
    _defaultHeaders.forEach((String name, Object value) {
      req.response.headers.add(name, value);
    });
    Map<String, Object> headers = response.headers;
    headers.forEach((String name, Object value) {
      req.response.headers.add(name, value);
    });
    req.response.statusCode = response.statusCode;
    try {
      req.response.write(JSON.encode(response.formatResponse()));
    } catch (err) {
      req.response.write(JSON.encode(new Response({"error": "server error"}, statusCode: 401).formatResponse()));
    }
    _logRequest(req);
    req.response.close();
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
       (LibraryMirror lm) => lm.qualifiedName == new Symbol(_libraryName));
      ClassMirror cm = lm.declarations[new Symbol(className + "Controller")];
      InstanceMirror im = cm.newInstance(new Symbol(''), []);
      return im;
  }

  /**
   *  Launches the router on the given [host] and [port]
   */
   Future launch(String host, int port) {
   return HttpServer.bind(host, port).then((HttpServer server) {
      httpServer = server;
      _logger.log(Log.Level.INFO, "listening on ${server.address}, port ${server.port}");
      var router = new Router(server);
      for (Route route in _routes) {
        for (String method in route.methods) {
          router.serve(route.url, method: method).listen(route.handler);
        }
      }
      _addOptionsHandler(router, _routes);
      router.defaultStream.listen(_defaultStream);
    });
  }

  /**
   * Create route for the method OPTIONS
   */
  void _addOptionsHandler(Router router, List<Route> routes) {
    var map = new Map<UrlPattern, List<String>>();
    for (Route route in routes) {
      if (route.options) {
        map.putIfAbsent(route.url, () => new List<String>());
        map[route.url].addAll(route.methods);
      }
    }
    map.forEach((url, final methods) {
      router.serve(url, method: "OPTIONS").listen((req) {
        req.response.statusCode = HttpStatus.NO_CONTENT;
        var methodString = "";
        for (var method in methods) {
          if (methodString != "") {
            methodString += ", ";
          }
          methodString += method;
        }
        _defaultHeaders.forEach((String name, Object value) {
          req.response.headers.add(name, value);
        });
        req.response.headers.add("Access-Control-Allow-Methods", methodString);
        req.response.headers.add("Cache-Control", "no-cache");
        req.response.headers.add("X-Dart-Framework", "SimpleDartApi");
        req.response.close();
      });
    });
  }

  /**
   * Handle the defaultStream
   */
  void _defaultStream(HttpRequest req) {
    if (req.method.toUpperCase() == "OPTIONS") {
      req.response.statusCode = HttpStatus.METHOD_NOT_ALLOWED;
      req.response.write("Not Allowed");
      req.response.close();
    } else {
      send404(req);
    }
  }

  /**
     * Logs a request [ctx]
     */
  void _logRequest(HttpRequest ctx) {
    if (ctx.response.statusCode > 400) {
      _logger.warning('"${ctx.method} ${ctx.requestedUri.path}" ${ctx.response.statusCode.toString()} - ${ctx.response.reasonPhrase}');
    } else {
      _logger.info("${ctx.connectionInfo.remoteAddress.address} - \"${ctx.method} ${ctx.requestedUri.path}\"  ${ctx.response.statusCode.toString()}"
""" \"${ctx.headers.host}\" \"${ctx.headers.value("user-agent")}\" """);
   }
  }

}
