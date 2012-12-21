module = angular.module 'Parse', []

module.factory 'Parse', ($http, $timeout, ParseConfig) ->
  Parse = {
    BaseUrl: "https://api.parse.com/1"
    
    _request: (method, path, data) ->
      if angular.isArray path
        [klass, id] = path
        path = "/classes/#{klass.className}/#{id}"
      else if path.className
        path = "/classes/#{path.className}"
      else if path.objectId and path.constructor?.className
        path = "/classes/#{path.constructor.className}/#{path.objectId}"

      headers = 
        "X-Parse-Application-Id": ParseConfig.applicationId
        "X-Parse-REST-API-KEY" : ParseConfig.apiKey

      $http
        method: method
        url:  Parse.BaseUrl + path
        data: data
        headers: headers
  }


  class Parse.Model 

    @find: (id) ->
      Parse._request('GET', "/classes/#{@className}/#{id}")
        .then (response) =>
          new @(response.data)
        

    @query: ->
      Parse._request('GET', @) 
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

    create: ->
      Parse._request('POST', @constructor, @attributes())
      .then (response) =>
        @objectId = response.data.objectId
        return @

    update: ->
      Parse._request('PUT', @, @attributes())
      .then (response) =>
        @objectId = response.data.objectId
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



  return Parse


