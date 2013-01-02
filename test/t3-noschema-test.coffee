should = require 'should'

simpleModel = ->
  v1 : 1
  v2 : "hello"

      

describe 'WHEN working with simple model and no schema', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "NoMappingsModel", 
    mappings: {}

  it 'IT should transform values unchanged', (done) ->
    apiFacade.mapRoot 'NonExistingModel', simpleModel(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1',1
      jsonObj.should.have.property 'v2',"hello"
      done null
  it 'IT should have no values if no mappings exist', (done) ->
    apiFacade.mapRoot 'NoMappingsModel', simpleModel(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.not.have.property 'v1'
      jsonObj.should.not.have.property 'v2'
      done null
