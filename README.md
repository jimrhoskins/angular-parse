# Parse for AngularJS

_This is pre-alpha/actively developed. There are no guarantees of
  stability, but you are welcome to play around and submit issues_

angular-parse is an [AngularJS](http://angularjs.org) module for
interacting with the [Parse](http://parse.com) [REST
API](https://parse.com/docs/rest). It *does not* utlize the [Parse
JavaScript API](https://parse.com/docs/js_guide) but instead is built
from (mostly) scratch. The reason is the existing Parse JavaScript API
is not ideal for AngularJS applications.

# Why Angular-Parse

There are a few things that are not ideal about the existing Parse
JavaScript API in AngularJS. The existing API is modeled after [Backbone
Models](http://backbonejs.org/#Model) and the main problem is setters
are used instead of object properties. `instance.set('property', 'value')` 
doesn't really fit well with things like `ng-model`

Instead, angular-parse is based loosely on [Spine
Models](http://spinejs.com/docs/models) where properties directly
defined on the object are used. To facilitate this, when defining a
model, it is "configured" by supplying the class name (as defined in
Parse) as well as which properties are part of that class.

Angular-parse also uses promises for any methods making network calls.

## Getting started

Include the JavaScript file

```html
<!-- Include AngularJS -->
<script src="path/to/angular-parse.js"></script>
```

Make sure to add `"Parse"` as a dependency of your main module

```javascript
var app = angular.module("YourApp", ["Parse"])
```

Angular-parse also requires you provide the value "ParseConfig" as an
object with the following format

```javascript
app.config(function (ParseProvider) {
  ParseProvider.initialize("PARSE_APPLICATION_ID", "PARSE_REST_API_KEY");
});
```

## Defining Models

You can define models by extending Parse.Model. You must call configure
on the class and pass it the Parse class name, and the name of any
attributes of that class

Using CoffeeScript:
```coffeescript
app.factory 'Car', (Parse) ->
  class Car extends Parse.model
    @configure "Car", "make", "model", "year"

    @customClassMethod: (arg) ->
      # add custom class methods like this

    customInstanceMethod: (arg) ->
      # add custom instance methods like this
```

Using JavaScript:
```javascript
// Not implemented yet, sorry
```

## Using Models

A model acts much the same as a normal JavaScript object with a
constructor

### Creating a new instance

You can create a new instance by using `new`. Any attributes passed in
will be set on the instance. This does not save it to parse, that must
be done with `.save()`. The save method returns a promise, which is
fulfilled with the instance itself.

```javascript
var car = new Car({
  make: "Scion",
  model: "xB",
  year: 2008
});

car.isNew() === true;
car.objectId == null;

car.save().then(function (_car) {
  _car === car;
  car.isNew() === false;
  car.objectId === "...aParseId";
  car.createdAt === "...aDateString";
  car.updatedAt === "...aDateString";
}
```

If the object has an objectId, it will be updated properly, and will not
create a new instance. `save()` can be used either for new or existing
records.

### Getting an instance By Id

The `find` method on your model class takes an objectId, and returns a
promise that will be fulfilled with your instance if it exists.


```javascript
Car.find("someObjectId").then(function (car) {
  car.objectId === "someObjectId";
})
```

### Destroying an instance

The destroy method on an instance will destroy it set destroyed to true
 and set the item's objectId to null

```javascript
Car.find("someObjectId").then(function (car) {
  car.objectId === "someObjectId";

  car.destroy().then(function (_car) {
    car === _car;
    car.destroyed === true;
    car.isNew() === true;
    car.objectId === null;
  })
})
```

### Defining a custom user class

A simple User class is provided to you. However, you can subclass it:

```coffeescript
angular.module('Parse').factory 'ParseCustomUser', (ParseDefaultUser) ->
      class CustomUser extends ParseDefaultUser
        @configure 'users', 'username', 'password', 'property'
```

In this manner, all User instances returned by the Parse methods
will be of your custom class.

### Contributing

Pull requests and issues are welcome.
