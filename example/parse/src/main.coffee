
Parse.Cloud.define "hello", (request, response) ->
  response.success("Hello coffee!")

Parse.Cloud.beforeSave 'Post', (req, res) ->
  post = req.object
  user = req.user

  unless user
    return res.error "You must be signed in to post."

  unless post.get("title").length
    return res.error "You must include a title"

  unless post.get("body").length
    return res.error "You must include a body"

  post.set('commentCount', post.get('commentCount') || 0)
  post.set('author', user)

  res.success()

Parse.Cloud.beforeSave 'Comment', (req, res) ->
  comment = req.object
  user = req.user

  unless user
    return res.error "You must be signed in to post."

  unless comment.get("body").length
    return res.error "You must include a body"

  comment.set('author', user)

  res.success()

