should = require 'should'

simpleModel = ->
  v1 : 1
  v2 : "hello"
  v3 : new Date(2013, 10, 20, 14, 50, 40, 1234)
  v4 : true
      

describe 'WHEN working with simple model and a more complex schema', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "SimpleModel", 
    mappings:
      v1a: 'v1'
      v2a: 
        name: 'v2'
      v3a: 'v3'
      v4a: 'v4'
      v5a: 
        name: 'v5'
        default: 'frank'

  it 'IT should transform values unchanged', (done) ->
    apiFacade.mapRoot 'SimpleModel', simpleModel(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1a',1
      jsonObj.should.have.property 'v2a',"hello"
      jsonObj.should.have.property 'v3a'
      jsonObj.v3a.toString().should.eql new Date(2013, 10, 20, 14, 50, 40, 1234).toString()
      jsonObj.should.have.property 'v4a',true
      jsonObj.should.have.property 'v5a',"frank"
      done null
      