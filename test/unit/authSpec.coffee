describe 'auth', ->
  backend = null
  signedHeaders = null
  url = null

  afterEach inject ($window) ->
    $window.localStorage.clear()


  beforeEach ->
    angular.module('ParseSpec', ['Parse']).config (ParseProvider) ->
      ParseProvider.initialize 'appId', 'apiKey'

    module 'ParseSpec'

    inject (Parse, $injector) ->
      # Helper method for matching API URLS
      url = (path) ->
        "#{Parse.BaseUrl}#{path}"

      backend = $injector.get('$httpBackend')

      signedHeaders = (headers) ->
        headers["X-Parse-Application-Id"] == 'appId' and
        headers["X-Parse-REST-API-KEY"] == "apiKey"

  afterEach ->
    backend.verifyNoOutstandingRequest()
    backend.verifyNoOutstandingExpectation()

  it 'has an auth property', inject (Parse) ->
    expect(Parse.auth).not.toBeUndefined()

  describe 'registering', ->

    beforeEach inject (Parse, $window) ->
      $window.localStorage = {}
      backend.expectPOST(
        url("/users"),
        {username: "johndoe", password: 'foobar'}
        signedHeaders
      ).respond(
        {
          "createdAt": "2011-11-07T20:58:34.448Z"
          "objectId": "g7y9tkhB7O"
          "sessionToken": "sessionTok"
        }
      )

      Parse.auth.register("johndoe", "foobar")
      backend.flush()

    it 'sets the session token', inject (Parse) ->
      expect(Parse.auth.sessionToken).toBe('sessionTok')

    it 'sets the current user', inject (Parse) ->
      user = Parse.auth.currentUser
      expect(user.objectId).toBe('g7y9tkhB7O')

    it 'clears the password on registation', inject ($window, Parse) ->
      user = Parse.auth.currentUser
      expect(user.password).toBeUndefined()


    it 'stores sessionId to localStorage', inject ($window) ->
      expect($window.localStorage.PARSE_SESSION_TOKEN).toBe 'sessionTok'

    it 'stores user to localStorage', inject ($window, Parse) ->
      info = Parse.auth.currentUser.attributes()
      info.objectId = Parse.auth.currentUser.objectId
      expect($window.localStorage.PARSE_USER_INFO).toBe JSON.stringify(info)

  describe 'logging out', ->
    beforeEach inject (Parse, $window) ->
      Parse.auth._login(user = new Parse.User(
        username: 'foo',
        sessionToken: 'sessionTok'
      ))

      expect(Parse.auth.currentUser.username).toBe 'foo'
      expect($window.localStorage.PARSE_USER_INFO).toBeTruthy()
      expect($window.localStorage.PARSE_SESSION_TOKEN).toBeTruthy()

      Parse.auth.logout()

    it 'clears localstorage sessionToken', inject ($window) ->
      expect($window.localStorage.PARSE_SESSION_TOKEN).toBeUndefined()

    it 'clears localstorage userInfo', inject ($window) ->
      expect($window.localStorage.PARSE_USER_INFO).toBeUndefined()

    it 'clears currentUser', inject (Parse) ->
      expect(Parse.auth.currentUser).toBeNull()

    it 'clears sessionToken', inject (Parse) ->
      expect(Parse.auth.sessionToken).toBeNull()


  describe 'resumeSession', ->
    describe 'with session data', ->
      user = null
      beforeEach inject (Parse, $window) ->
        user = new Parse.User
          username: 'foobar'
          sessionToken: 'sessTok'
        $window.localStorage.setItem('PARSE_USER_INFO', JSON.stringify(user.attributes()))
        $window.localStorage.setItem('PARSE_SESSION_TOKEN', user.sessionToken)

      it 'exists', inject (Parse) ->
        Parse.auth.resumeSession()

      it 'sets the currentUser', inject (Parse) ->
        Parse.auth.resumeSession()
        expect(Parse.auth.currentUser.username).toBe 'foobar'

      it 'sets the sessionToken', inject (Parse) ->
        Parse.auth.resumeSession()
        expect(Parse.auth.sessionToken).toBe 'sessTok'

    describe 'without session data', ->
      it 'doesnt set the currentUser', inject (Parse) ->
        Parse.auth.resumeSession()
        expect(Parse.auth.currentUser).toBeNull()

      it 'doesnt set the sessionToken', inject (Parse) ->
        Parse.auth.resumeSession()
        expect(Parse.auth.sessionToken).toBeNull()
