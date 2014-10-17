part of SimpleDartApi;

class Middleware {

  // Middleware's contructor
  Middleware();

  /**
   * Execute the middleware before each request return false if everything is good,
   * or return the good Response.
   */
  execute(HttpRequest req, Route route){
    return false;
  }

}