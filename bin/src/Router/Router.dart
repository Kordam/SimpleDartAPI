library router;

import "dart:io";
import "dart:mirrors";
import "dart:convert";
import "dart:collection";
import "package:express/express.dart";
import 'package:logging/logging.dart' as Log;
import "package:yaml/yaml.dart";
import "../Controllers/ControllersLibrary.dart"; // Needed to generate Classes and call functions dynamicaly
part "Middleware.dart";
part "NotFound.dart";
part "Route.dart";

class Router {

  Express                     _express = new Express();
  String                      _routingDir = "/src/";
  Map<String, InstanceMirror> _classes = {};
  Log.Logger                  _logger = new Log.Logger("Routeur");

  /**
   * Router's contructor
   * Take the path to the routes directory as pathToRoot
   */
  Router (String pathToRoute) {
    _routingDir += pathToRoute;
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
    _express.use(new NotFound());
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
    new Directory(Directory.current.path + _routingDir).listSync(recursive: true, followLinks: false)
    .forEach((FileSystemEntity entity) {
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
      current_roads.forEach((String routeName, Map info) {
        Route route = _getRouteInfo(version, routeName, info);
        _createRoute(route);
      });

      if (previous_routes != null) {
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
      route.url = "/" + version  + info["route"];
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
      return route;
  }


  /**
   * Creates the route by [url] and crete them for each methods of the [route]
   */
  void _createRoute(Route route) {
    route.methods.forEach((method) {
      switch (method) {
        case "GET":
          _express.get(route.url, (HttpContext ctx) {_handleRequest(ctx, route);});
          break;
        case "POST":
          _express.post(route.url, (HttpContext ctx) {_handleRequest(ctx, route);});
          break;
        case "PUT":
          _express.put(route.url, (HttpContext ctx) {_handleRequest(ctx, route);});
          break;
        case "DELETE":
          _express.delete(route.url, (HttpContext ctx) {_handleRequest(ctx, route);});
          break;
        default:
          _express.any(route.url, (HttpContext ctx) {_handleRequest(ctx, route);});
          break;
        }
    });
  }

  /**
   * Checks if the request contains some data dans callthe Middleware
   */
  void _handleRequest(HttpContext ctx, Route route) {
    if (ctx.contentLength == -1) {
      _handleMiddleware(ctx, route);
    } else {
      ctx.readAsJson().then((Map<String, String> data) {
        _handleMiddleware(ctx, route, data);
      }).catchError((x) {
        Response response = new Response("Unexpected error", statusCode: 500);
        ctx.sendJson(response.formatResponse(), httpStatus: response.statusCode);
      });
    }
    _logRequest(ctx);
  }

  /**
   * Calls the middleware with the request asked [ctx] to know if the request can be executed.
   * If the middleware responde false then [classFunction] if called using [im] generated class
   */
  void _handleMiddleware(HttpContext ctx, Route route, [Map<String, String> data]) {
    Map parameters = new Map();
    ctx.params.forEach((key, value) => parameters.putIfAbsent(key, () => value));
    if (data != null)
       data.forEach((key, value) => parameters.putIfAbsent(key, () => value));
    var response = new Middleware().execute(ctx, route);
    if (response == false) {
      response = route.classe.invoke(new Symbol(route.function), [parameters]).reflectee;
    }
    ctx.sendJson((response as Response).formatResponse(), httpStatus: (response as Response).statusCode);
  }

  /**
   * Creates dynamicaly a class by it's name.
   * Returns an instance of the given class
   */
  InstanceMirror _createClass(String className) {
    MirrorSystem mirrors = currentMirrorSystem();
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
    _express.listen(host, port);
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
