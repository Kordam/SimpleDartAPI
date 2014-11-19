#SimpleDartAPI

SimpleDartAPI is a Dart Framework that will allow you to easily create your own API in Dart.
This Framework is based on the [route package](https://pub.dartlang.org/packages/route) and allows you to create your route simply by configuring a YAML configuration file.

#Installation

To install SimpleDartAPI you can either download this git repository :
```
 git clone git@github.com:Kordam/SimpleDartAPI.git
```

Or simply by adding this lign to your pubsec.yaml file :

```
simple_dart_api: 0.0.7
```
And launching the command `pub get`

#Usage

This section will describe the basic things that you must implement to make the SimpleDartAPI work.

Firstly you have to include the package containing all the tools needed to use the SimpleDartAPI:
```
import 'package:simple_dart_api/simple_dart_api.dart';
```

Then you need to include the library containing all the controllers for your API.** This step is crucial for the SimpleDartAPI to work well ** :
```
import 'Controllers/ControllersLibrary.dart';
```

Once you've done that, you're ready to begin your server. To do so you we create a SimpleDartApi object with the path to the routes of your API :
```
var router = new SimpleDartApi(Directory.current.path + "/Routes/");
```

We then launch the server on a defined host and port :
```
router.launch("127.0.0.1", 8001);
```

Here is the result of what your main should look like :

```
import 'dart:io' show Directory;
import 'package:simple_dart_api/simple_dart_api.dart';

// Import all the controllers from your API to be executed by the Simple Dart API
import 'Controllers/ControllersLibrary.dart';

main() {
  var router = new SimpleDartApi(Directory.current.path + "/Routes/");
  router.launch("127.0.0.1", 8001);
}
```

And there you go your API is up and running. Well not yet completely we still have to create the routes and controllers in order to have some content in it.

## Routes

### Directory's organisation

The SimpleDartAPI implements a versioning system that will allow you to create different versions of your API without worrying about maintaining the previously defined routes. 
Each version of your API is represented by a directory. The name of the directory represents the version number of your API.
Inside your version directory you can put all your routes in multiple YAML files as so :

```
├── Routes
│   ├── 0.1
│   │   ├── User.yaml
│   │   └── Product.yaml
│   ├── 0.2
│       └── User.yaml
```

In this example the directory `Routes` is the directory given as a parameter to the SimpleDartAPI. The directories `0.1` and `0.2` are your API's versions and the YAML file contains your routes.

### Defining a route

Here is an example of a routing file :
```
user_create:
  route: /user/create
  method: PUT
  action: User:create
  options: true

user_get:
  route: /user/(\d+)/get
  method: GET
  action: User:get

user_edit:
  route: /user/(\d+)/edit
  method: POST
  action: User:edit
  needConnection: true

user_delete:
  route: /user/(\d+)/delete
  method: DELETE
  action: User:delete
```

This syntax is composed of 6 parts:

1. **The route name (`user_create`)**: This name must be unique. It is the identifier of the route itself and is used in case of multiple versions to automatically create the road for the higher version.

2. **The route URI (`route: /user/create`)**: This is the URI which will be accessible via the API. This will be prefixed by the version number of the API (directory name). For example the route `/user/create/` for the version *0.1* will become `/0.1/user/create/`.
The routes are treated like in the Route package, to pass a GET parameter to the route you can use the syntax of the regular expressions. The parameters will be sent to your controller in the same order that they were defined in the route.

3. **The methods (`method: PUT`)**: These are the methods allowed to access the route. The treated methods are *GET, POST, PUT, DELETE, ANY*. If you use the method *ANY*, the route can be accessed with any type of method. This value is applied by default if the line is not specified. 
You can define multiple types of methods by separating them with the character *"|"* : `method: GET | POST `.

4. **The action (`action: User:create`)**: It is the action done when the request is treated by the Router. It is separated in two parts :
   * `User` : Representing the controller containing the treatment function of the route.
   * `create` : The controller's function that will be called by the Router.

5. ** The need of connection (`needConnection: true`)**: Allows you to specify if the road needs an identification to be accessed. You might need it to disallow pages in the *Middleware*. Default value is `false`.

6. **The handling of the OPTIONS requests (`options: true`)**: Allow you to specify if the route needs to answer the OPTIONS request or not.

Now that we have our routes set up we only need to create the controllers for these routes.

## Controllers

The Controllers are classes containing the functions called during the routing. Those classes must be part of a single library in order to be dynamically created by the SimpleDartAPI. By default the name of that library must be **controllers** but you can customize that name by sending a parameter `libraryName` to the constructor of the SimpleDartAPI. 
The name of a controller class is formatted according to the following rule: **controller_name** followed by the suffix *Controller*, for example the controller *User* must be called *UserController*.
To create a Controller you have to add it in the *controllers* library and name it as defined previously.

The controller contained functions, which are called during the routing process are formated in the following way:
```
Response create(HttpRequest req, String name) {
  return new Response("Get User");
}
```
Those function firstly take the Request itself as a parameter which contains all the information of the sent request.
Secondly it take the series of parameter of the Request such as the GET and POST parameters. Those parameters are positioned in the same order as defined in the route file for the GET ones or in the request for the others.

Those functions return either :
* A Response object with the data, status code and headers
* A Future containing either a Response or raw data that will then be transform in a Response object
* Raw data that will then be transform in a Response object

## Responses

In order to standardise the responses from the API a **Response** class has been created. This class is created from a dataset and a status code.
You also have the possibility to use your own custom headers by specifying them in the contructor.

```dart
Response response = new Response("Not found", statusCode: 404, headers: {'Access-Control-Allow-Origin': '*'});
```

The first parameter is the data sent back from the API. You can use any type of data (String, List, Map, int, etc...), the Response class will transform it to *JSON* to make it more easily usable for the client part.
The second parameter is optional and corresponds to the status code sent by the API. By default it is set to 200.
The last one is also optional and is the headers of the response, it must be a Map of String.

# Other functionalities

## Middleware

SimpleDartAPI's Router has a MiddleWare functionality that allows you to execute a function before each request.
To use the Middleware of the SmpleDartAPI you need to create your own class and implement it from the class `MiddlewareController` of the SimpleDartAPI and override the method execute of that class. Then you simply have to create an instance of your class and set the attribute of the SimpleDartAPI class.

Here's what your Middleware class should look like
```
import 'dart:io';
import 'package:simple_dart_api/simple_dart_api.dart';

class MyMiddleware implements MiddlewareController {

  @override
  Future execute(HttpRequest req, Route route){
    if ((new Date()).millisecondsSinceEpoch % 42 != 0)
      throw new Response("It's not a good time to ask a question !", statusCode: 403);
    return Future.wait([]);
  }

}
```
And simply add the functionality like so :
```
router.middlewares.add(new MyMiddleware());
```

The function *execute* takes two parameters, the context containing the Request itself and the Route information contained in the configuration file.
If everything is OK then the function must return `true` and the Router of the SimpleDartAI will call the appropriate Controller. Otherwise it returns a Response object with the proper data and status code.

## Logs

The simple dart implements a log function that logs every request sent to the server.
The `logs` directory will contain all the logs generated by the server. Each request asked to the API is logged as an info or a warning.
In the `info.log` are logged all the requests that receive the 200 status code and are therefore validated by the server.
In the `warning.log` are logged all the requests containing errors.

Each input in those files contains information about the request and the response (ip, route, method, etc ...)
