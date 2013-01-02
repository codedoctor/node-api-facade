should = require 'should'

simpleModel = ->
  v1 : 1
  v2 : "hello"
  v3 : new Date(2013, 10, 20, 14, 50, 40, 1234)
  v4 : true
      

describe 'WHEN working with simple model', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "SimpleModel", 
    mappings:
      v1 : 'v1'
      v2 : 'v2'
      v3 : 'v3'
      v4 : 'v4'

  it 'IT should transform values unchanged', (done) ->
    apiFacade.mapRoot 'SimpleModel', simpleModel(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1',1
      jsonObj.should.have.property 'v2',"hello"
      jsonObj.should.have.property 'v3'
      jsonObj.v3.toString().should.eql new Date(2013, 10, 20, 14, 50, 40, 1234).toString()
      jsonObj.should.have.property 'v4',true
      done null
      