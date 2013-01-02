should = require 'should'

modelNoData = ->
  v1 : null
  v2 : null

describe 'WHEN working with types', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "TypeA", 
    mappings:
      v1: 
        name: 'v1a'
        type: 'TypeB'
      v2: 
        name: 'v2a'
        type: 'TypeB'
        collectionType: 'Array'

  apiFacade.addSchema "TypeB", 
    mappings:
      b1: 
        name: 'b1a'

  it 'IT should transform values unchanged', (done) ->
    apiFacade.mapRoot 'TypeA', modelNoData(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.not.have.property 'v1a'
      jsonObj.should.have.property 'v2a'
      jsonObj.v2a.should.be.an.instanceOf(Array)
      jsonObj.v2a.should.have.lengthOf 0
      done null
      