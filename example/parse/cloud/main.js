
Parse.Cloud.define("hello", function(request, response) {
  return response.success("Hello coffee!");
});

Parse.Cloud.beforeSave('Post', function(req, res) {
  var post, user;
  post = req.object;
  user = req.user;
  if (!user) {
    return res.error("You must be signed in to post.");
  }
  if (!post.get("title").length) {
    return res.error("You must include a title");
  }
  if (!post.get("body").length) {
    return res.error("You must include a body");
  }
  post.set('commentCount', post.get('commentCount') || 0);
  post.set('author', user);
  return res.success();
});

Parse.Cloud.beforeSave('Comment', function(req, res) {
  var comment, user;
  comment = req.object;
  user = req.user;
  if (!user) {
    return res.error("You must be signed in to post.");
  }
  if (!comment.get("body").length) {
    return res.error("You must include a body");
  }
  comment.set('author', user);
  return res.success();
});
