part of SimpleDartApi;

abstract class MiddlewareController {

  /**
   * Execute the middleware before each request return false if everything is good,
   * or return the good Response.
   */
  Future execute(HttpRequest req, Route route);

}