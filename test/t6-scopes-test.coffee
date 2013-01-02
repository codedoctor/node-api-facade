should = require 'should'

modelData = ->
  v1 : 'hello'
  v2 : 'hello2'
  v3 : 'hello3'
  v4 : 'hello4'
  v5 : 'hello5'


describe 'WHEN working with scopes', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "NoScopes", 
    mappings:
      v1: 'v1'
      v2: 'v2'
      v3: 'v3'
      v4: 'v4'
      v5: 'v5'

  apiFacade.addSchema "WithScopes", 
    mappings:
      v1: 'v1'
      v2: 'v2'
      v3: 'v3'
      v4: 'v4'
      v5: 'v5'
    scopes:
      scopea: 
        fields: ['v1','v2','v3']

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

  it 'IT should ignore the scope if none are defined in the schema', (done) ->
    apiFacade.mapRoot 'WithScopes', modelData(), scopes : ['scopea'], (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1','hello'
      jsonObj.should.have.property 'v2','hello2'
      jsonObj.should.have.property 'v3','hello3'
      jsonObj.should.not.have.property 'v4'
      jsonObj.should.not.have.property 'v5'
      done null
