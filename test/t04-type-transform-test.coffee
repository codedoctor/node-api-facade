should = require 'should'

modelNoData = ->
  v1 : null
  v2 : null

modelData = ->
  v1 : 
    b1 : "Hello"
  v2 : 
    b1 : "Hello"

modelDataWithArray = ->
  v2 : [
    b1 : "Hello"
   ,
    b1 : "Hello2"
   ]
describe 'WHEN working with types', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "TypeA", 
    mappings:
      v1a: 
        name: 'v1'
        type: 'TypeB'
      v2a: 
        name: 'v2'
        type: 'TypeB'
        collectionType: 'Array'

  apiFacade.addSchema "TypeB", 
    mappings:
      b1a: 
        name: 'b1'

  it 'IT should transform values', (done) ->
    apiFacade.mapRoot 'TypeA', modelNoData(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.not.have.property 'v1a'
      jsonObj.should.have.property 'v2a'
      jsonObj.v2a.should.be.an.instanceOf(Array)
      jsonObj.v2a.should.have.lengthOf 0
      done null

  it 'IT should ...', (done) ->
    apiFacade.mapRoot 'TypeA', modelData(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1a'
      jsonObj.v1a.should.have.property "b1a",'Hello'

      jsonObj.should.have.property 'v2a'
      jsonObj.v2a.should.be.an.instanceOf(Array)
      jsonObj.v2a.should.have.lengthOf 1
      jsonObj.v2a[0].should.have.property "b1a",'Hello'
      done null
      
  it 'IT should ...', (done) ->
    apiFacade.mapRoot 'TypeA', modelDataWithArray(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v2a'
      jsonObj.v2a.should.be.an.instanceOf(Array)
      jsonObj.v2a.should.have.lengthOf 2
      jsonObj.v2a[0].should.have.property "b1a",'Hello'
      jsonObj.v2a[1].should.have.property "b1a",'Hello2'
      done null
