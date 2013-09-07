module = angular.module 'Parse', []

CONFIG = {}

module.factory 'persist', ($q, $window) ->
  store = $window.localStorage

  persist =
    get: (keys) ->
      keys = [keys] unless angular.isArray keys
      result = {}
      for key in keys
        if store.key key
          result[key] = store.getItem key
        else
          result[key] = undefined
      result

    set: (obj) ->
      for own key, val of obj
        store.setItem key, val
      true

    remove: (keys) ->
      keys = [keys] unless angular.isArray keys
      for key in keys
        localStorage.removeItem key
      true

module.factory 'ParseUtils', ($http, $window) ->
  Parse =
    BaseUrl: "https://api.parse.com/1"

    _request: (method, path, data, params) ->

      if angular.isArray path
        [klass, id] = path
        path = "#{klass.pathBase()}/#{id}"
      else if path.className
        path = "#{path.pathBase()}"
      else if path.objectId and path.constructor?.className
        path = "#{path.constructor.pathBase()}/#{path.objectId}"

      headers =
        "X-Parse-Application-Id": CONFIG.applicationId
        "X-Parse-REST-API-KEY" : CONFIG.apiKey
        "Content-Type" : "application/json"

      if $window.localStorage.key('PARSE_SESSION_TOKEN')
        headers["X-Parse-Session-Token"] = $window.localStorage.getItem('PARSE_SESSION_TOKEN')

      $http
        method: method
        url:  @BaseUrl + path
        data: data
        params: params
        headers: headers

    func: (name) ->
      (data) -> Parse.callFunction name, data

    callFunction: (name, data) ->
      Parse._request("POST", "/functions/#{name}", data).then (r) ->
        r.data.result

module.factory 'ParseAuth', (persist, ParseUser, ParseUtils, $q) ->
  auth =
    sessionToken: null
    currentUser: null

    _login: (user) ->
      auth.currentUser = user
      auth.sessionToken = user.sessionToken
      info = user.attributes()
      info.objectId = user.objectId
      persist.set
        PARSE_USER_INFO: JSON.stringify(info)
        PARSE_SESSION_TOKEN:  user.sessionToken
      user

    resumeSession: ->
      results = persist.get(['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO'])
      userAttrs = results.PARSE_USER_INFO
      sessionToken = results.PARSE_SESSION_TOKEN
      deferred = $q.defer();
      if userAttrs and sessionToken
        try
          user = new ParseUser(JSON.parse(userAttrs))
          auth.currentUser = user
          auth.sessionToken = sessionToken
          deferred.resolve(user.refresh())
        catch e
          deferred.reject('User attributes not parseable')
      else
        deferred.reject('User attributes or Session Token not found')
      return deferred.promise

    register: (username, password) ->
      new ParseUser(
        username: username
        password: password
      ).save().then (user) ->
        auth._login(user)

    login: (username, password) ->
      ParseUtils._request("GET", "/login", null, {
        username: username
        password: password
      })
        .then (response) ->
          auth._login( new ParseUser(response.data))

    logout: ->
      persist.remove ['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']
      auth.currentUser = null
      auth.sessionToken = null

module.factory 'ParseModel', (ParseUtils) ->
  class Model
    @pathBase: ->
      "/classes/#{@className}"

    @find: (id, params) ->
      ParseUtils._request('GET', "/classes/#{@className}/#{id}", null, params)
        .then (response) =>
          new @(response.data)

    @query: (params) ->
      ParseUtils._request('GET', @, null, params)
      .then (response) =>
        for item in response.data.results
          new @(item)

    @configure: (name, attributes...) ->
      @className = name
      @attributes = attributes

    constructor: (data) ->
      for key, value of data
        @[key] = value
      @_saveCache()

    isNew: =>
      !@objectId

    save: =>
      if @isNew()
        @create()
      else
        @update()

    refresh: =>
      ParseUtils._request('GET', @).then (response) =>
        for own key, value of response.data
          @[key] = value
        @

    create: =>
      ParseUtils._request('POST', @constructor, @encodeParse())
      .then (response) =>
        @objectId = response.data.objectId
        @createdAt = response.data.createdAt
        if token = response.data.sessionToken
          @sessionToken = token
        @_saveCache()
        return @

    update: =>
      ParseUtils._request('PUT', @, @encodeParse())
      .then (response) =>
        @updatedAt = response.data.updatedAt
        @_saveCache()
        return @

    destroy: =>
      ParseUtils._request('DELETE', @)
      .then (response) =>
        @objectId = null
        return @

    attributes: =>
      result = {}
      for key in @constructor.attributes
        result[key] = @[key]
      result

    encodeParse: =>
      result = {}
      for key in @constructor.attributes
        if key of this
          obj = @[key]

          if obj? and obj.objectId and obj.constructor?.className
            # Pointer
            obj = {
              __type: "Pointer"
              className: obj.constructor.className
              objectId: obj.objectId
            }

          result[key] = obj

      result

    _saveCache: =>
      @_cache = angular.copy @encodeParse()

    isDirty: =>
      not angular.equals @_cache, @encodeParse()

module.factory 'ParseDefaultUser', (ParseModel) ->
  class User extends ParseModel
    @configure 'users', 'username', 'password'
    @pathBase: -> "/users"

    save: ->
      super().then (user) =>
        delete user.password
        user

module.factory 'ParseUser', (ParseDefaultUser, ParseCustomUser) ->
  if ParseCustomUser? and (new ParseCustomUser instanceof ParseDefaultUser)
    return ParseCustomUser
  else
    return ParseDefaultUser

module.provider 'Parse', ->
  return {
    initialize: (applicationId, apiKey) ->
      CONFIG.apiKey = apiKey
      CONFIG.applicationId = applicationId

    $get: (ParseModel, ParseUser, ParseAuth, ParseUtils) ->
      BaseUrl: ParseUtils.BaseUrl
      Model: ParseModel
      User: ParseUser
      auth: ParseAuth
  }

angular.module('Parse').factory 'ParseCustomUser', (ParseDefaultUser) ->
  ParseDefaultUser