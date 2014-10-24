part of controllers;

class UserController {

    Response create(HttpRequest req, String name) {
      // create the user ...
      return new Response({'msg': "create a user", 'id': name});
    }

    Response get(HttpRequest req, String id) {
      // get the user ...
      var headers = {'header': '*'};
      return new Response({'msg': "get a user", 'id': id}, headers: headers);
    }

    Future<Response> futureget(HttpRequest req, String id) {
      Completer completer = new Completer();
      Future future = new File("example.txt").readAsString();
      future.then((content) {
        completer.complete(content);
      });
      return completer.future;
    }

    Response edit(HttpRequest req, String id) {
      // edit the user ...
      return new Response({'msg': "edit a user", 'id': id});
    }

    Response delete(HttpRequest req, String id) {
      // delete the user ...
      return new Response({'msg': "delete a user", 'id': id});
    }
}