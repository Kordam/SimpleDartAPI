part of SimpleDartApi;

class Response {
  var _data;
  Map<String, Object> _headers = new Map<String, Object>();
  Map<String, Object> get headers => _headers;
  int _statusCode = 200;
  int get statusCode => _statusCode;

  /**
   * Create a response to be sent to the client containing tthe given data and status code.
   * By default the status code is 200
   */
  Response(this._data, {int statusCode, Map<String, Object> headers}) {
    if (statusCode is int)
      _statusCode = statusCode;
    if (headers is Map<String, Object>)
      _headers = headers;
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