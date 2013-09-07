includes = (expected) ->
  x = ->
  x.test = (str) ->
    try
      data = JSON.parse str
      for key, value of expected
        return false unless data[key] == value
      return true
    catch e
      return false
  x.toString = ->
    "Include #{angular.toJson expected}"
  x

describe 'Model', ->
  url = null
  backend = null
  signedHeaders = null

  Car = null

  beforeEach ->
    angular.module('ParseSpec', ['Parse']).config (ParseProvider) ->
      ParseProvider.initialize 'appId', 'apiKey'

    module 'ParseSpec'

    inject ($injector, Parse) ->
      url = (path) ->
        "#{Parse.BaseUrl}#{path}"

      backend = $injector.get('$httpBackend')

      signedHeaders = (headers) ->
        headers["X-Parse-Application-Id"] == 'appId' and
        headers["X-Parse-REST-API-KEY"] == "apiKey"

      class Car extends Parse.Model
        @configure 'Car', 'make', 'model', 'year', 'parts'

  afterEach ->
    backend.verifyNoOutstandingExpectation()
    backend.verifyNoOutstandingRequest()


  it 'exists', inject (Parse) ->
    expect(Parse.Model).not.toBeNull()

  it 'allows configuration', inject (Parse) ->
    class Car extends Parse.Model
      @configure 'Car', 'make', 'model', 'color'

    expect(Car.className).toEqual 'Car'
    expect(Car.attributes).toEqual ['make', 'model', 'color']

  describe 'create', ->

    it 'calls POST on collection', inject () ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"

      backend.expectPOST(
        url("/classes/Car"),
        JSON.stringify(car.attributes())
      ).respond
        createdAt: "2011-08-20T02:06:57.931Z"
        objectId: "foobarbaz"

      car.save().then (c) ->
        expect(c).toBe(car)

      backend.flush()
      expect(car.objectId).toEqual('foobarbaz')
      expect(car.isNew()).toEqual(false)

  describe 'update', ->

    it 'calls PUTS on a resource', inject () ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"
        objectId: 'existingID123'

      backend.expectPUT(
        url("/classes/Car/existingID123"),
        includes(car.attributes()),
        signedHeaders

      ).respond
        updatedAt: "2012-08-20T02:06:57.931Z"

      car.save().then (c) ->
        expect(c).toBe(car)

      backend.flush()
      expect(car.updatedAt).toEqual('2012-08-20T02:06:57.931Z')
      expect(car.isNew()).toEqual(false)

  describe 'isDirty', ->

    it 'is not dirty upon creation', ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"
        objectId: 'existingID123'
        parts: ['engine', 'chassis']

      expect(car.isDirty()).toBe(false)

    it 'is dirty upon updating', ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"
        objectId: 'existingID123'
        parts: ['engine', 'chassis']

      car.model = "Corolla"
      expect(car.isDirty()).toBe(true)

    it 'is not dirty when returning to old state', ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"
        objectId: 'existingID123'
        parts: ['engine', 'chassis']

      car.model = "Corolla"
      expect(car.isDirty()).toBe(true)
      car.model = "Camry"
      expect(car.isDirty()).toBe(false)

      car.parts.push('tires')
      expect(car.isDirty()).toBe(true)
      car.parts.splice(2, 1)
      expect(car.isDirty()).toBe(false)

    it 'updates its cache on save', ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"
        objectId: 'existingID123'
        parts: ['engine', 'chassis']

      car.model = "Corolla"
      expect(car.isDirty()).toBe(true)
      backend.expectPUT(
        url("/classes/Car/existingID123"),
        car.attributes(),
        signedHeaders

      ).respond
        updatedAt: "2012-08-20T02:06:57.931Z"

      car.save().then (c) ->
        expect(c).toBe(car)
        expect(car.isDirty()).toBe(false)

      backend.flush()

  describe 'destroy', ->

    it 'calls DELETE on a resource', inject () ->
      car = new Car
        make: "Toyota"
        year: 2005
        model: "Camry"
        objectId: 'existingID123'

      backend.expectDELETE(
        url("/classes/Car/existingID123"),
        signedHeaders
      ).respond
        createdAt: "2011-08-20T02:06:57.931Z"
        objectId: "foobarbaz"

      car.destroy().then (c) ->
        expect(c.isNew()).toBe(true)

      backend.flush()

  describe 'find', ->
    it 'returns by id', ->
      backend.expectGET(
        url("/classes/Car/objID123")
        signedHeaders
      ).respond
        objectId: "objID123"
        createdAt: "2011-08-20T02:06:57.931Z"
        updatedAt: "2011-08-20T02:06:57.931Z"
        make: "Scion"
        model: "xB"
        year: 2008

      Car.find('objID123').then (car) ->
        expect(car.isNew()).toBe false
        expect(car.objectId).toEqual 'objID123'
        expect(car.make).toBe 'Scion'
        expect(car.model).toBe 'xB'
        expect(car.year).toBe 2008

      backend.flush()

  describe 'query', ->
    it 'queries the api', ->
      backend.expectGET(
        url("/classes/Car")
        signedHeaders
      ).respond
        results: [
          {
            objectId: "objID1"
            createdAt: "2011-08-20T02:06:57.931Z"
            updatedAt: "2011-08-20T02:06:57.931Z"
            make: "Scion"
            model: "xB"
            year: 2008
          }
          {
            objectId: "objID2"
            createdAt: "2011-08-20T02:06:57.931Z"
            updatedAt: "2011-08-20T02:06:57.931Z"
            make: "Toyota"
            model: "Camry"
            year: 2005
          }
        ]
      Car.query().then (cars) ->
        expect(cars.length).toBe 2
        expect(cars[0].isNew()).toBe false
        expect(cars[0].objectId).toBe "objID1"
        expect(cars[1].objectId).toBe "objID2"
        expect(cars[1].model).toBe "Camry"

      backend.flush()

describe 'User', ->

  it 'should not have custom property', ->
    angular.module('ParseSpec', ['Parse']).config (ParseProvider) ->
      ParseProvider.initialize 'appId', 'apiKey'

    module 'ParseSpec'

    inject (ParseUser) ->
      expect(ParseUser).toBeDefined()
      expect(ParseUser.attributes).toContain('username')
      expect(ParseUser.attributes).not.toContain('property')

  it 'should have property when extended', ->
    angular.module('Parse').factory 'ParseCustomUser', (ParseDefaultUser) ->
      class CustomUser extends ParseDefaultUser
        @configure 'users', 'username', 'password', 'property'

    angular.module('ParseSpec', ['Parse']).config (ParseProvider) ->
      ParseProvider.initialize 'appId', 'apiKey'

    module 'ParseSpec'

    inject (ParseUser) ->
      expect(ParseUser).toBeDefined()
      expect(ParseUser.attributes).toContain('username')
      expect(ParseUser.attributes).toContain('property')