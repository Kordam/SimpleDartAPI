part of SimpleDartApi;

class Response {
  var _data;
  int _statusCode = 200;
  get statusCode => _statusCode;

  /**
   * Create a response to be sent to the client containing tthe given data and status code.
   * By default the status code is 200
   */
  Response(this._data, {int statusCode}) {
    if (statusCode is int)
      _statusCode = statusCode;
  }

  /**
   *  Uniformise the response and return a Map containing the results
   */
  Map formatResponse() {
    Map results = new Map();
    if (_statusCode == 200) {
      results["data"] = _data;
      results["status"] = "ok";
    } else {
      results["data"] = {"error": _data};
      results["status"] = "ko";
    }
    return  results;
  }

}