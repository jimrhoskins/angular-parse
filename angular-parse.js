(function() {
  var module,
    __hasProp = {}.hasOwnProperty,
    __slice = [].slice,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module = angular.module('Parse', []);

  module.factory('persist', function($q, $window) {
    var persist, store;
    store = $window.localStorage;
    return persist = {
      get: function(keys) {
        var key, result, _i, _len;
        if (!angular.isArray(keys)) {
          keys = [keys];
        }
        result = {};
        for (_i = 0, _len = keys.length; _i < _len; _i++) {
          key = keys[_i];
          if (store.key(key)) {
            result[key] = store.getItem(key);
          } else {
            result[key] = void 0;
          }
        }
        return $q.when(result);
      },
      set: function(obj) {
        var key, val;
        for (key in obj) {
          if (!__hasProp.call(obj, key)) continue;
          val = obj[key];
          store.setItem(key, val);
        }
        return $q.when(true);
      },
      remove: function(keys) {
        var key, _i, _len;
        if (!angular.isArray(keys)) {
          keys = [keys];
        }
        for (_i = 0, _len = keys.length; _i < _len; _i++) {
          key = keys[_i];
          localStorage.removeItem(key);
        }
        return $q.when(true);
      }
    };
  });

  module.provider('Parse', function() {
    var CONFIG;
    CONFIG = {};
    return {
      initialize: function(applicationId, apiKey) {
        CONFIG.apiKey = apiKey;
        return CONFIG.applicationId = applicationId;
      },
      $get: function($http, $timeout, persist) {
        var Parse;
        Parse = {
          BaseUrl: "https://api.parse.com/1",
          _request: function(method, path, data, params) {
            var headers, id, isUserClass, klass, _ref;
            if (angular.isArray(path)) {
              klass = path[0], id = path[1];
              path = "" + (klass.pathBase()) + "/" + id;
            } else if (path.className) {
              isUserClass = path.isUserClass;
              path = "" + (path.pathBase());
            } else if (path.objectId && ((_ref = path.constructor) != null ? _ref.className : void 0)) {
              isUserClass = path.constructor.isUserClass;
              path = "" + (path.constructor.pathBase()) + "/" + path.objectId;
            }
            headers = {
              "X-Parse-Application-Id": CONFIG.applicationId,
              "X-Parse-REST-API-KEY": CONFIG.apiKey,
              "Content-Type": "application/json"
            };
            if (Parse.auth.sessionToken) {
              headers["X-Parse-Session-Token"] = Parse.auth.sessionToken;
            }
            return $http({
              method: method,
              url: Parse.BaseUrl + path,
              data: data,
              params: params,
              headers: headers
            });
          },
          func: function(name) {
            return function(data) {
              return Parse.callFunction(name, data);
            };
          },
          callFunction: function(name, data) {
            return Parse._request("POST", "/functions/" + name, data).then(function(r) {
              return r.data.result;
            });
          },
          auth: {
            sessionToken: null,
            currentUser: null,
            _login: function(user) {
              var info;
              Parse.auth.currentUser = user;
              Parse.auth.sessionToken = user.sessionToken;
              info = user.attributes();
              info.objectId = user.objectId;
              persist.set({
                PARSE_USER_INFO: JSON.stringify(info),
                PARSE_SESSION_TOKEN: user.sessionToken
              });
              return user;
            },
            resumeSession: function() {
              return persist.get(['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']).then(function(r) {
                var sessionToken, user, userAttrs;
                userAttrs = r.PARSE_USER_INFO;
                sessionToken = r.PARSE_SESSION_TOKEN;
                if (userAttrs && sessionToken) {
                  try {
                    user = new Parse.User(JSON.parse(userAttrs));
                    Parse.auth.currentUser = user;
                    Parse.auth.sessionToken = sessionToken;
                    return user.refresh();
                  } catch (e) {
                    return false;
                  }
                }
              });
            },
            register: function(username, password) {
              return new Parse.User({
                username: username,
                password: password
              }).save().then(function(user) {
                return Parse.auth._login(user);
              });
            },
            login: function(username, password) {
              return Parse._request("GET", "/login", null, {
                username: username,
                password: password
              }).then(function(response) {
                return Parse.auth._login(new Parse.User(response.data));
              });
            },
            logout: function() {
              persist.remove(['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']);
              Parse.auth.currentUser = null;
              return Parse.auth.sessionToken = null;
            }
          }
        };
        Parse.Model = (function() {

          Model.pathBase = function() {
            return "/classes/" + this.className;
          };

          Model.find = function(id, params) {
            var _this = this;
            return Parse._request('GET', "/classes/" + this.className + "/" + id, null, params).then(function(response) {
              return new _this(response.data);
            });
          };

          Model.query = function(params) {
            var _this = this;
            return Parse._request('GET', this, null, params).then(function(response) {
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

          Model.prototype.refresh = function() {
            var _this = this;
            return Parse._request('GET', this).then(function(response) {
              var key, value, _ref;
              _ref = response.data;
              for (key in _ref) {
                if (!__hasProp.call(_ref, key)) continue;
                value = _ref[key];
                _this[key] = value;
              }
              return _this;
            });
          };

          Model.prototype.create = function() {
            var _this = this;
            return Parse._request('POST', this.constructor, this.encodeParse()).then(function(response) {
              var token;
              _this.objectId = response.data.objectId;
              _this.createdAt = response.data.createdAt;
              if (token = response.data.sessionToken) {
                _this.sessionToken = token;
              }
              return _this;
            });
          };

          Model.prototype.update = function() {
            var _this = this;
            return Parse._request('PUT', this, this.encodeParse()).then(function(response) {
              _this.updatedAt = response.data.updatedAt;
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

          Model.prototype.encodeParse = function() {
            var key, obj, result, _i, _len, _ref, _ref1;
            result = {};
            _ref = this.constructor.attributes;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              key = _ref[_i];
              if (key in this) {
                obj = this[key];
                if (obj.objectId && ((_ref1 = obj.constructor) != null ? _ref1.className : void 0)) {
                  obj = {
                    __type: "Pointer",
                    className: obj.constructor.className,
                    objectId: obj.objectId
                  };
                }
                result[key] = obj;
              }
            }
            return result;
          };

          return Model;

        })();
        Parse.User = (function(_super) {

          __extends(User, _super);

          function User() {
            return User.__super__.constructor.apply(this, arguments);
          }

          User.configure('users', 'username', 'password');

          User.pathBase = function() {
            return "/users";
          };

          User.prototype.save = function() {
            var _this = this;
            console.log(this);
            return User.__super__.save.call(this).then(function(user) {
              delete user.password;
              return user;
            });
          };

          return User;

        })(Parse.Model);
        return Parse;
      }
    };
  });

}).call(this);
