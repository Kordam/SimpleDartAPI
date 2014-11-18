part of controllers;

class DisplayRoute_MiddlewareController implements MiddlewareController {

   /**
    * Execute the middlewares before each request return false if everything is good,
    * or return the good Response.
    */
   @override
   Future execute(HttpRequest req, Route route) {
     print("Route: " + req.uri.path);
     
     var completer = new Completer();
     completer.complete();
     return completer.future;
   }

}