(function() {
  var CONFIG, module,
    __hasProp = {}.hasOwnProperty,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  module = angular.module('Parse', []);

  CONFIG = {};

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
        return result;
      },
      set: function(obj) {
        var key, val;
        for (key in obj) {
          if (!__hasProp.call(obj, key)) continue;
          val = obj[key];
          store.setItem(key, val);
        }
        return true;
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
        return true;
      }
    };
  });

  module.factory('ParseUtils', function($http, $window) {
    var Parse;
    return Parse = {
      BaseUrl: "https://api.parse.com/1",
      _request: function(method, path, data, params) {
        var headers, id, klass, _ref;
        if (angular.isArray(path)) {
          klass = path[0], id = path[1];
          path = "" + (klass.pathBase()) + "/" + id;
        } else if (path.className) {
          path = "" + (path.pathBase());
        } else if (path.objectId && ((_ref = path.constructor) != null ? _ref.className : void 0)) {
          path = "" + (path.constructor.pathBase()) + "/" + path.objectId;
        }
        headers = {
          "X-Parse-Application-Id": CONFIG.applicationId,
          "X-Parse-REST-API-KEY": CONFIG.apiKey,
          "Content-Type": "application/json"
        };
        if ($window.localStorage.key('PARSE_SESSION_TOKEN')) {
          headers["X-Parse-Session-Token"] = $window.localStorage.getItem('PARSE_SESSION_TOKEN');
        }
        return $http({
          method: method,
          url: this.BaseUrl + path,
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
      }
    };
  });

  module.factory('ParseAuth', function(persist, ParseUser, ParseUtils, $q) {
    var auth;
    return auth = {
      sessionToken: null,
      currentUser: null,
      _login: function(user) {
        var info;
        auth.currentUser = user;
        auth.sessionToken = user.sessionToken;
        info = user.attributes();
        info.objectId = user.objectId;
        persist.set({
          PARSE_USER_INFO: JSON.stringify(info),
          PARSE_SESSION_TOKEN: user.sessionToken
        });
        return user;
      },
      resumeSession: function() {
        var deferred, e, results, sessionToken, user, userAttrs;
        results = persist.get(['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']);
        userAttrs = results.PARSE_USER_INFO;
        sessionToken = results.PARSE_SESSION_TOKEN;
        deferred = $q.defer();
        if (userAttrs && sessionToken) {
          try {
            user = new ParseUser(JSON.parse(userAttrs));
            auth.currentUser = user;
            auth.sessionToken = sessionToken;
            deferred.resolve(user.refresh());
          } catch (_error) {
            e = _error;
            deferred.reject('User attributes not parseable');
          }
        } else {
          deferred.reject('User attributes or Session Token not found');
        }
        return deferred.promise;
      },
      register: function(username, password) {
        return new ParseUser({
          username: username,
          password: password
        }).save().then(function(user) {
          return auth._login(user);
        });
      },
      login: function(username, password) {
        return ParseUtils._request("GET", "/login", null, {
          username: username,
          password: password
        }).then(function(response) {
          return auth._login(new ParseUser(response.data));
        });
      },
      logout: function() {
        persist.remove(['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']);
        auth.currentUser = null;
        return auth.sessionToken = null;
      }
    };
  });

  module.factory('ParseModel', function(ParseUtils) {
    var Model;
    return Model = (function() {
      Model.pathBase = function() {
        return "/classes/" + this.className;
      };

      Model.find = function(id, params) {
        var _this = this;
        return ParseUtils._request('GET', "/classes/" + this.className + "/" + id, null, params).then(function(response) {
          return new _this(response.data);
        });
      };

      Model.query = function(params) {
        var _this = this;
        return ParseUtils._request('GET', this, null, params).then(function(response) {
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
        this.isDirty = __bind(this.isDirty, this);
        this._saveCache = __bind(this._saveCache, this);
        this.encodeParse = __bind(this.encodeParse, this);
        this.attributes = __bind(this.attributes, this);
        this.destroy = __bind(this.destroy, this);
        this.update = __bind(this.update, this);
        this.create = __bind(this.create, this);
        this.refresh = __bind(this.refresh, this);
        this.save = __bind(this.save, this);
        this.isNew = __bind(this.isNew, this);
        var key, value;
        for (key in data) {
          value = data[key];
          this[key] = value;
        }
        this._saveCache();
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
        return ParseUtils._request('GET', this).then(function(response) {
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
        return ParseUtils._request('POST', this.constructor, this.encodeParse()).then(function(response) {
          var token;
          _this.objectId = response.data.objectId;
          _this.createdAt = response.data.createdAt;
          if (token = response.data.sessionToken) {
            _this.sessionToken = token;
          }
          _this._saveCache();
          return _this;
        });
      };

      Model.prototype.update = function() {
        var _this = this;
        return ParseUtils._request('PUT', this, this.encodeParse()).then(function(response) {
          _this.updatedAt = response.data.updatedAt;
          _this._saveCache();
          return _this;
        });
      };

      Model.prototype.destroy = function() {
        var _this = this;
        return ParseUtils._request('DELETE', this).then(function(response) {
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
            if ((obj != null) && obj.objectId && ((_ref1 = obj.constructor) != null ? _ref1.className : void 0)) {
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

      Model.prototype._saveCache = function() {
        return this._cache = angular.copy(this.encodeParse());
      };

      Model.prototype.isDirty = function() {
        return !angular.equals(this._cache, this.encodeParse());
      };

      return Model;

    })();
  });

  module.factory('ParseDefaultUser', function(ParseModel) {
    var User, _ref;
    return User = (function(_super) {
      __extends(User, _super);

      function User() {
        _ref = User.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      User.configure('users', 'username', 'password');

      User.pathBase = function() {
        return "/users";
      };

      User.prototype.save = function() {
        var _this = this;
        return User.__super__.save.call(this).then(function(user) {
          delete user.password;
          return user;
        });
      };

      return User;

    })(ParseModel);
  });

  module.factory('ParseUser', function(ParseDefaultUser, ParseCustomUser) {
    if ((ParseCustomUser != null) && (new ParseCustomUser instanceof ParseDefaultUser)) {
      return ParseCustomUser;
    } else {
      return ParseDefaultUser;
    }
  });

  module.provider('Parse', function() {
    return {
      initialize: function(applicationId, apiKey) {
        CONFIG.apiKey = apiKey;
        return CONFIG.applicationId = applicationId;
      },
      $get: function(ParseModel, ParseUser, ParseAuth, ParseUtils) {
        return {
          BaseUrl: ParseUtils.BaseUrl,
          Model: ParseModel,
          User: ParseUser,
          auth: ParseAuth
        };
      }
    };
  });

  angular.module('Parse').factory('ParseCustomUser', function(ParseDefaultUser) {
    return ParseDefaultUser;
  });

}).call(this);
