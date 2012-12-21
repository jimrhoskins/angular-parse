var app = angular.module('parseExample', ['Parse']);

app.controller('demo', function ($q, Parse) {


  Parse.Model.configure("Car", "make", "model")
  window.c = new Parse.Model
  x = c.save()
  x.then(function(){
    alert('win')
  }, function () {
    alert('lose')
  })

  window.x = x
  
})
