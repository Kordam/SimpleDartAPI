part of router;

class Middleware {

  // Middleware's contructor
  Middleware();

  /**
   * Execute the middleware before each request return false if everything is good,
   * or return the good Response.
   */
  execute(HttpContext ctx, Route route){
    return false;
  }

}