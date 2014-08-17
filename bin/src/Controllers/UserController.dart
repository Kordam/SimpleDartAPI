part of controllers;

class UserController {
    /**
     * Create a user by the information contained in [params]
     */
    Response create(Map params) {
      return new Response("Create User");
    }

    Response get(Map params) {
      String id = params["userId"];
      return new Response("Get User");
    }

    Response edit(Map params) {
      String id = params["userId"];
      return new Response("Edit User");
    }

    Response delete(Map params) {
      String id = params["userId"];
      return new Response("Delete User");
    }
}