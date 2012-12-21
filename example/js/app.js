var app,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

app = angular.module('CarDealer', ['Parse']);

app.config(function($routeProvider) {
  return $routeProvider.when("/", {
    controller: "CarList",
    templateUrl: "partials/list.html"
  }).when("/new-car", {
    controller: "CarForm",
    templateUrl: "partials/form.html"
  }).when("/cars/:id", {
    controller: "CarDetail",
    templateUrl: "partials/detail.html"
  }).when("/edit-car/:id", {
    controller: "CarForm",
    templateUrl: "partials/form.html"
  }).otherwise({
    redirectTo: "/"
  });
});

app.value('ParseConfig', {
  applicationId: "OczAR6VkElaVe5012kOHccwSJSdd3xtU1jBXRBDK",
  apiKey: "OtKOw3a45SBJL7AesN2kymOJwD0cG9YTdaOAi9BF"
});

app.factory('Car', function(Parse) {
  var Car;
  return Car = (function(_super) {

    __extends(Car, _super);

    function Car() {
      return Car.__super__.constructor.apply(this, arguments);
    }

    Car.configure('Car', 'make', 'model', 'year');

    return Car;

  })(Parse.Model);
});

app.controller('CarList', function($scope, Car) {
  $scope.load = function() {
    return Car.query().then(function(cars) {
      return $scope.cars = cars;
    });
  };
  $scope.destroy = function(car) {
    return car.destroy().then(function() {
      return $scope.load();
    });
  };
  return $scope.load();
});

app.controller('CarDetail', function($scope, $routeParams, Car) {
  var id;
  id = $routeParams.id;
  return Car.find(id).then(function(car) {
    return $scope.car = car;
  });
});

app.controller('CarForm', function($scope, $location, $routeParams, Car) {
  var id;
  id = $routeParams.id;
  if (id) {
    Car.find(id).then(function(car) {
      return $scope.car = car;
    });
  } else {
    $scope.car = new Car;
  }
  return $scope.save = function() {
    var _ref;
    return (_ref = $scope.car) != null ? _ref.save().then(function(car) {
      return $location.path("/");
    }) : void 0;
  };
});
