part of router;

class NotFound implements Module {

  void register(Express server) =>
    server.addRequestHandler((req) => true, (ctx) => execute(ctx));

  void execute(HttpContext ctx) {
    ctx.notFound("Page not found", new JsonEncoder().convert({"error": "Page not found"}));
  }
}