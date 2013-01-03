should = require 'should'

modelData = ->
  v1x : 'hello'
  v2x : 'hello2'
  v3x : 'hello3'
  v4x : 'hello4'
  v5x : 'hello5'


describe 'WHEN working with scopes', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "NoScopes", 
    mappings:
      v1: 'v1x'
      v2: 'v2x'
      v3: 'v3x'
      v4: 'v4x'
      v5: 'v5x'

  apiFacade.addSchema "WithScopes", 
    mappings:
      v1: 'v1x'
      v2: 'v2x'
      v3: 'v3x'
      v4: 'v4x'
      v5: 'v5x'
    scopes:
      scopea: 
        fields: ['v1','v2','v3']

  apiFacade.addSchema "WithTwoScopes", 
    mappings:
      v1: 'v1x'
      v2: 'v2x'
      v3: 'v3x'
      v4: 'v4x'
      v5: 'v5x'
    scopes:
      scopea: 
        fields: ['v1','v2','v3']
      scopeb: 
        fields: ['v3','v4']

  apiFacade.addSchema "WithRestrictScopes", 
    mappings:
      v1: 'v1x'
      v2: 'v2x'
      v3: 'v3x'
      v4: 'v4x'
      v5: 'v5x'
    scopes:
      scopea: 
        fields: ['v1','v2','v3']
      scopeb: 
        fields: ['v3','v4']
        mode: 'restrict'

  it 'IT should ignore the scope if none are defined in the schema', (done) ->
    apiFacade.mapRoot 'NoScopes', modelData(), scopes : ['scopea'], (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1','hello'
      jsonObj.should.have.property 'v2','hello2'
      jsonObj.should.have.property 'v3','hello3'
      jsonObj.should.have.property 'v4','hello4'
      jsonObj.should.have.property 'v5','hello5'
      done null

  it 'IT should...', (done) ->
    apiFacade.mapRoot 'WithScopes', modelData(), scopes : ['scopea'], (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1','hello'
      jsonObj.should.have.property 'v2','hello2'
      jsonObj.should.have.property 'v3','hello3'
      jsonObj.should.not.have.property 'v4'
      jsonObj.should.not.have.property 'v5'
      done null

  it 'IT should...', (done) ->
    apiFacade.mapRoot 'WithTwoScopes', modelData(), scopes : ['scopea','scopeb'], (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1','hello'
      jsonObj.should.have.property 'v2','hello2'
      jsonObj.should.have.property 'v3','hello3'
      jsonObj.should.have.property 'v4','hello4'
      jsonObj.should.not.have.property 'v5'
      done null

  it 'IT should...', (done) ->
    apiFacade.mapRoot 'WithRestrictScopes', modelData(), scopes : ['scopea','scopeb'], (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.not.have.property 'v1'
      jsonObj.should.not.have.property 'v2'
      jsonObj.should.have.property 'v3','hello3'
      jsonObj.should.not.have.property 'v4'
      jsonObj.should.not.have.property 'v5'
      done null
