(function() {
  var app,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

  app = angular.module('Forum', ['Parse']);

  app.run(function(Parse) {
    return Parse.auth.resumeSession();
  });

  app.config(function(ParseProvider, $routeProvider) {
    var findPostById;
    ParseProvider.initialize("x58FvFYxi4SDIRdJck4hFVv1huo8F409UnfERfUU", "ixgyh7GKI1eLSU7PYrDuuOEh31CAlYmCXS7tuJ5p");
    findPostById = function(Post, $route) {
      var id;
      if (id = $route.current.params.id) {
        return Post.find(id, {
          include: "author"
        });
      } else {
        return new Post;
      }
    };
    return $routeProvider.when("/", {
      controller: "PostList",
      templateUrl: "partials/list.html"
    }).when("/register", {
      controller: "RegisterCtrl",
      templateUrl: "partials/register.html"
    }).when("/sign-in", {
      controller: "SignInCtrl",
      templateUrl: "partials/sign-in.html"
    }).when("/new-post", {
      controller: "PostForm",
      templateUrl: "partials/form.html",
      resolve: {
        $post: findPostById
      }
    }).when("/posts/:id", {
      controller: "PostDetail",
      templateUrl: "partials/detail.html",
      resolve: {
        $post: findPostById
      }
    }).when("/edit-post/:id", {
      controller: "PostForm",
      templateUrl: "partials/form.html",
      resolve: {
        $post: findPostById
      }
    }).otherwise({
      redirectTo: "/"
    });
  });

  app.factory('Post', function(Parse) {
    var Post, _ref;
    return Post = (function(_super) {
      __extends(Post, _super);

      function Post() {
        _ref = Post.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Post.configure('Post', 'title', 'body', 'author', 'tags', 'commentCount');

      return Post;

    })(Parse.Model);
  });

  app.factory('Comment', function(Parse) {
    var Comment, _ref;
    return Comment = (function(_super) {
      __extends(Comment, _super);

      function Comment() {
        _ref = Comment.__super__.constructor.apply(this, arguments);
        return _ref;
      }

      Comment.configure('Comment', 'author', 'post', 'body');

      return Comment;

    })(Parse.Model);
  });

  app.controller('PostList', function($scope, Post) {
    $scope.load = function() {
      return Post.query({
        include: 'author'
      }).then(function(posts) {
        return $scope.posts = posts;
      });
    };
    $scope.destroy = function(post) {
      return post.destroy().then(function() {
        return $scope.load();
      });
    };
    return $scope.load();
  });

  app.controller('PostDetail', function($scope, $routeParams, $post, Comment) {
    var loadComments;
    $scope.post = $post;
    $scope.comments = [];
    loadComments = function() {
      return Comment.query({
        where: {
          post: {
            __type: 'Pointer',
            className: 'Post',
            objectId: $post.objectId
          }
        },
        include: 'author'
      }).then(function(comments) {
        $scope.comments = comments;
        return console.log(comments);
      }, function() {
        return console.log(arguments);
      });
    };
    $scope.$on('new-comment', loadComments);
    return loadComments();
  });

  app.controller('PostForm', function($scope, $location, Post) {
    $scope.post = new Post;
    $scope.hideForm = true;
    return $scope.save = function() {
      var _ref;
      return (_ref = $scope.post) != null ? _ref.save().then(function(post) {
        console.log(post);
        return $location.path("/posts/" + post.objectId);
      }, function(res) {
        return console.log(res);
      }) : void 0;
    };
  });

  app.controller('CommentForm', function($scope, Comment) {
    $scope.comment = new Comment({
      post: $scope.post
    });
    console.log($scope.comment);
    return $scope.save = function() {
      return $scope.comment.save().then(function() {
        console.log('S', arguments);
        $scope.$emit('new-comment');
        $scope.comment = new Comment({
          post: $scope.post
        });
        return $scope.numRows = 1;
      }, function() {
        return console.log('F', arguments);
      });
    };
  });

  app.controller('AuthCtrl', function($scope, Parse) {
    $scope.auth = Parse.auth;
    return $scope.signout = function() {
      return Parse.auth.logout();
    };
  });

  app.controller('RegisterCtrl', function($location, $window, $scope, Parse) {
    $scope.auth = Parse.auth;
    $scope.user = {};
    $scope.errorMessage = null;
    return $scope.register = function(user) {
      if (user.password !== user.passwordConfirm) {
        return $scope.errorMessage = "Passwords must match";
      }
      if (!(user.username && user.password)) {
        return $scope.errorMessage = 'Please supply a username and password';
      }
      return Parse.auth.register(user.username, user.password).then(function() {
        return $location.path("/");
      }, function(err) {
        return $scope.errorMessage = err.data.error;
      });
    };
  });

  app.controller('SignInCtrl', function($location, $window, $scope, Parse) {
    $scope.auth = Parse.auth;
    $scope.user = {};
    $scope.errorMessage = null;
    return $scope.signin = function(user) {
      if (!(user.username && user.password)) {
        return $scope.errorMessage = 'Please supply a username and password';
      }
      return Parse.auth.login(user.username, user.password).then(function() {
        console.log('in', arguments);
        return $location.path("/");
      }, function(err) {
        console.log('out', arguments);
        return $scope.errorMessage = err.data.error;
      });
    };
  });

}).call(this);
