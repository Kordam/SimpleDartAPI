import 'dart:io';
import 'package:simple_dart_api/simple_dart_api.dart';

class MyMiddleware extends Middleware  {

  @override
  execute(HttpRequest req, Route route){
    /*
     * You can return either true to continue or the appropriate Response
     *
     * return new Response("Bad request", statusCode:  400);
     */
    return true;
  }

}


