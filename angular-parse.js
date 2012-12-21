(function() {
  var module,
    __slice = [].slice;

  module = angular.module('Parse', []);

  module.factory('Parse', function($http, $timeout, ParseConfig) {
    var Parse;
    Parse = {
      BaseUrl: "https://api.parse.com/1",
      _request: function(method, path, data) {
        var headers, id, klass, _ref;
        if (angular.isArray(path)) {
          klass = path[0], id = path[1];
          path = "/classes/" + klass.className + "/" + id;
        } else if (path.className) {
          path = "/classes/" + path.className;
        } else if (path.objectId && ((_ref = path.constructor) != null ? _ref.className : void 0)) {
          path = "/classes/" + path.constructor.className + "/" + path.objectId;
        }
        headers = {
          "X-Parse-Application-Id": ParseConfig.applicationId,
          "X-Parse-REST-API-KEY": ParseConfig.apiKey
        };
        return $http({
          method: method,
          url: Parse.BaseUrl + path,
          data: data,
          headers: headers
        });
      }
    };
    Parse.Model = (function() {

      Model.find = function(id) {
        var _this = this;
        return Parse._request('GET', "/classes/" + this.className + "/" + id).then(function(response) {
          return new _this(response.data);
        });
      };

      Model.query = function() {
        var _this = this;
        return Parse._request('GET', this).then(function(response) {
          var item, _i, _len, _ref, _results;
          _ref = response.data.results;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            item = _ref[_i];
            _results.push(new _this(item));
          }
          return _results;
        });
      };

      Model.configure = function() {
        var attributes, name;
        name = arguments[0], attributes = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
        this.className = name;
        return this.attributes = attributes;
      };

      function Model(data) {
        var key, value;
        for (key in data) {
          value = data[key];
          this[key] = value;
        }
      }

      Model.prototype.isNew = function() {
        return !this.objectId;
      };

      Model.prototype.save = function() {
        if (this.isNew()) {
          return this.create();
        } else {
          return this.update();
        }
      };

      Model.prototype.create = function() {
        var _this = this;
        return Parse._request('POST', this.constructor, this.attributes()).then(function(response) {
          _this.objectId = response.data.objectId;
          return _this;
        });
      };

      Model.prototype.update = function() {
        var _this = this;
        return Parse._request('PUT', this, this.attributes()).then(function(response) {
          _this.objectId = response.data.objectId;
          return _this;
        });
      };

      Model.prototype.destroy = function() {
        var _this = this;
        return Parse._request('DELETE', this).then(function(response) {
          _this.objectId = null;
          return _this;
        });
      };

      Model.prototype.attributes = function() {
        var key, result, _i, _len, _ref;
        result = {};
        _ref = this.constructor.attributes;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          result[key] = this[key];
        }
        return result;
      };

      return Model;

    })();
    return Parse;
  });

}).call(this);
