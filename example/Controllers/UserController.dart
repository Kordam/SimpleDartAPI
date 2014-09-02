part of controllers;

class UserController {
    /**
     * Create a user by the information contained in [params]
     */
    void create(HttpRequest req, String id) {
      req.response.write(id);
    }

    void get(HttpRequest req, String id) {
      req.response.write(id);
    }

    void edit(HttpRequest req, String id) {
      req.response.write(id);
    }

    void delete(HttpRequest req, String id) {
      req.response.write(id);
    }
}