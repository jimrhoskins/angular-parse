app = angular.module 'Forum', ['Parse']

app.run (Parse) ->
  Parse.auth.resumeSession()

app.config (ParseProvider, $routeProvider) ->
  ParseProvider.initialize(
    "x58FvFYxi4SDIRdJck4hFVv1huo8F409UnfERfUU",
    "ixgyh7GKI1eLSU7PYrDuuOEh31CAlYmCXS7tuJ5p"
  )
  findPostById = (Post, $route) ->
    if id = $route.current.params.id
      Post.find(id, include: "author")
    else
      new Post


  $routeProvider
    .when("/", controller: "PostList", templateUrl: "partials/list.html")
    .when("/register",
      controller: "RegisterCtrl"
      templateUrl: "partials/register.html"
    )
    .when("/sign-in",
      controller: "SignInCtrl"
      templateUrl: "partials/sign-in.html"
    )
    .when("/new-post", 
      controller: "PostForm"
      templateUrl: "partials/form.html"
      resolve:
        $post: findPostById
    )
    .when("/posts/:id", 
      controller: "PostDetail"
      templateUrl: "partials/detail.html"
      resolve:
        $post: findPostById
    )
    .when("/edit-post/:id",
      controller: "PostForm"
      templateUrl: "partials/form.html"
      resolve:
        $post: findPostById
    )
    .otherwise(redirectTo: "/")


app.factory 'Post', (Parse) ->
  class Post extends Parse.Model
    @configure 'Post', 'title', 'body', 'author', 'tags', 'commentCount'

app.factory 'Comment', (Parse) ->
  class Comment extends Parse.Model
    @configure 'Comment', 'author', 'post', 'body'


app.controller 'PostList', ($scope, Post) ->
  $scope.load = ->
    Post.query({include: 'author'}).then (posts) ->
      $scope.posts = posts

  $scope.destroy = (post) ->
    post.destroy().then -> $scope.load()

  $scope.load()

app.controller 'PostDetail', ($scope, $routeParams, $post, Comment) ->
  $scope.post = $post
  $scope.comments = []

  loadComments = ->
    Comment.query(
      where:
        post:
          __type: 'Pointer'
          className: 'Post'
          objectId: $post.objectId
      include: 'author'
    ).then (comments) ->
      $scope.comments = comments
      console.log comments
    , ->
      console.log arguments

  $scope.$on 'new-comment', loadComments
  loadComments()

app.controller 'PostForm', ($scope, $location, Post) ->
  $scope.post = new Post
  $scope.hideForm = true

  $scope.save = ->
    $scope.post?.save().then (post) ->
      console.log post
      $location.path("/posts/#{post.objectId}")
    , (res) ->
      console.log res

app.controller 'CommentForm', ($scope, Comment) ->
  $scope.comment = new Comment(post: $scope.post)
  console.log $scope.comment

  $scope.save = ->
    $scope.comment.save().then ->
      console.log 'S', arguments
      $scope.$emit 'new-comment'
      $scope.comment = new Comment(post: $scope.post)
      $scope.numRows = 1
    , ->
      console.log 'F', arguments


app.controller 'AuthCtrl', ($scope, Parse) ->
  $scope.auth = Parse.auth
  $scope.signout = ->
    Parse.auth.logout()

app.controller 'RegisterCtrl', ($location, $window, $scope, Parse) ->
  $scope.auth = Parse.auth
  $scope.user = {}
  $scope.errorMessage = null

  $scope.register = (user) ->
    if user.password isnt user.passwordConfirm
      return $scope.errorMessage = "Passwords must match"

    unless user.username and user.password
      return $scope.errorMessage = 'Please supply a username and password'

    Parse.auth.register(user.username, user.password).then ->
      $location.path("/")
    , (err) ->
      $scope.errorMessage = err.data.error


app.controller 'SignInCtrl', ($location, $window, $scope, Parse) ->
  $scope.auth = Parse.auth
  $scope.user = {}
  $scope.errorMessage = null

  $scope.signin = (user) ->
    unless user.username and user.password
      return $scope.errorMessage = 'Please supply a username and password'

    Parse.auth.login(user.username, user.password).then ->
      console.log 'in', arguments
      $location.path("/")
    , (err) ->
      console.log 'out', arguments
      $scope.errorMessage = err.data.error

