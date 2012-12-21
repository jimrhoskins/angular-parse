app = angular.module 'CarDealer', ['Parse']

app.config ($routeProvider) ->
  $routeProvider
    .when("/", controller: "CarList", templateUrl: "partials/list.html")
    .when("/new-car", controller: "CarForm", templateUrl: "partials/form.html")
    .when("/cars/:id", controller: "CarDetail", templateUrl: "partials/detail.html")
    .when("/edit-car/:id", controller: "CarForm", templateUrl: "partials/form.html")
    .otherwise(redirectTo: "/")

app.value 'ParseConfig', 
  applicationId: "OczAR6VkElaVe5012kOHccwSJSdd3xtU1jBXRBDK"
  apiKey: "OtKOw3a45SBJL7AesN2kymOJwD0cG9YTdaOAi9BF"

app.factory 'Car', (Parse) ->
  class Car extends Parse.Model
    @configure 'Car', 'make', 'model', 'year'


app.controller 'CarList', ($scope, Car) ->
  $scope.load = ->
    Car.query().then (cars) ->
      $scope.cars = cars

  $scope.destroy = (car) ->
    car.destroy().then -> $scope.load()

  $scope.load()

app.controller 'CarDetail', ($scope, $routeParams, Car) ->
  id = $routeParams.id
  Car.find(id).then (car) ->
    $scope.car = car

app.controller 'CarForm', ($scope, $location, $routeParams, Car) ->
  id = $routeParams.id

  if id
    Car.find(id).then (car) ->
      $scope.car = car
  else
    $scope.car = new Car

  $scope.save = ->
    $scope.car?.save().then (car) ->
      $location.path("/")

