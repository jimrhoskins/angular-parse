module = angular.module 'Parse', []

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
      $q.when(result)

    set: (obj) ->
      for own key, val of obj
        store.setItem key, val
      $q.when true

    remove: (keys) ->
      keys = [keys] unless angular.isArray keys
      for key in keys
        localStorage.removeItem key
      $q.when true

module.provider 'Parse', ->
  CONFIG = {}
  return {
    initialize: (applicationId, apiKey) ->
      CONFIG.apiKey = apiKey
      CONFIG.applicationId = applicationId

    $get: ($http, $timeout, persist ) ->

      Parse = {
        BaseUrl: "https://api.parse.com/1"

        _request: (method, path, data, params) ->

          if angular.isArray path
            [klass, id] = path
            path = "#{klass.pathBase()}/#{id}"
          else if path.className
            isUserClass = path.isUserClass
            path = "#{path.pathBase()}"
          else if path.objectId and path.constructor?.className
            isUserClass = path.constructor.isUserClass
            path = "#{path.constructor.pathBase()}/#{path.objectId}"

          headers = 
            "X-Parse-Application-Id": CONFIG.applicationId
            "X-Parse-REST-API-KEY" : CONFIG.apiKey
            "Content-Type" : "application/json"

          if Parse.auth.sessionToken
            headers["X-Parse-Session-Token"] = Parse.auth.sessionToken

          $http
            method: method
            url:  Parse.BaseUrl + path
            data: data
            params: params
            headers: headers

        func: (name) ->
          (data) -> Parse.callFunction name, data

        callFunction: (name, data) ->
          Parse._request("POST", "/functions/#{name}", data).then (r) ->
            r.data.result

        auth: 
          sessionToken: null
          currentUser: null

          _login: (user) ->
            Parse.auth.currentUser = user
            Parse.auth.sessionToken = user.sessionToken
            info = user.attributes()
            info.objectId = user.objectId
            persist.set
              PARSE_USER_INFO: JSON.stringify(info)
              PARSE_SESSION_TOKEN:  user.sessionToken
            #localStorage.PARSE_USER_INFO= JSON.stringify(info)
            #localStorage.PARSE_SESSION_TOKEN = user.sessionToken
            user

          resumeSession: ->
            #userAttrs = localStorage.PARSE_USER_INFO
            #sessionToken = localStorage.PARSE_SESSION_TOKEN
            persist.get(['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']).then (r) ->
              userAttrs = r.PARSE_USER_INFO
              sessionToken = r.PARSE_SESSION_TOKEN
              if userAttrs and sessionToken
                try
                  user = new Parse.User(JSON.parse(userAttrs))
                  Parse.auth.currentUser = user
                  Parse.auth.sessionToken = sessionToken
                  user.refresh()

                catch e
                  false

          register: (username, password) ->
            new Parse.User(
              username: username
              password: password
            ).save().then (user) ->
              Parse.auth._login(user)

          login: (username, password) ->
            Parse._request("GET", "/login", null, {
              username: username
              password: password
            })
            .then (response) ->
              Parse.auth._login( new Parse.User(response.data))

          logout: ->
            persist.remove ['PARSE_SESSION_TOKEN', 'PARSE_USER_INFO']
            #delete localStorage.PARSE_SESSION_TOKEN 
            #delete localStorage.PARSE_USER_INFO
            Parse.auth.currentUser = null
            Parse.auth.sessionToken = null
      }

      class Parse.Model 
        @pathBase: ->
          "/classes/#{@className}"

        @find: (id, params) ->
          Parse._request('GET', "/classes/#{@className}/#{id}", null, params)
            .then (response) =>
              new @(response.data)

        @query: (params) ->
          Parse._request('GET', @, null, params) 
          .then (response) =>
            for item in response.data.results
              new @(item)

        @configure: (name, attributes...) ->
          @className = name
          @attributes = attributes


        constructor: (data) ->
          for key, value of data
            @[key] = value

        isNew: ->
          !@objectId

        save: ->
          if @isNew()
            @create()
          else
            @update()

        refresh: ->
          Parse._request('GET', @).then (response) =>
            for own key, value of response.data
              @[key] = value
            @

        create: ->
          Parse._request('POST', @constructor, @encodeParse())
          .then (response) =>
            @objectId = response.data.objectId
            @createdAt = response.data.createdAt
            if token = response.data.sessionToken
              @sessionToken = token
            return @

        update: ->
          Parse._request('PUT', @, @encodeParse())
          .then (response) =>
            @updatedAt = response.data.updatedAt
            return @

        destroy: ->
          Parse._request('DELETE', @)
          .then (response) =>
            @objectId = null
            return @

        attributes: ->
          result = {}
          for key in @constructor.attributes
            result[key] = @[key]
          result

        encodeParse: ->
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

      class Parse.User extends Parse.Model
        @configure 'users', 'username', 'password'
        @pathBase: -> "/users"

        save: ->
          console.log this
          super().then (user) =>
            delete user.password
            user

      return Parse

  }
