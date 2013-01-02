should = require 'should'

modelData = ->
  v1 : 'hello'

modelDataWithArray = ->
  v1 : ['hello','hello2']

describe 'WHEN working with an array', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "TypeA", 
    mappings:
      v1: 
        name: 'v1a'
        collectionType: 'Array'


  it 'IT should transform basic string into an array if the collectionType is an array', (done) ->
    apiFacade.mapRoot 'TypeA', modelData(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1a'
      jsonObj.v1a.should.be.an.instanceOf(Array)
      jsonObj.v1a.should.have.lengthOf 1
      jsonObj.v1a[0].should.eql "hello"
      done null

  it 'IT should transform an array of strings into an array if the collectionType is an array', (done) ->
    apiFacade.mapRoot 'TypeA', modelDataWithArray(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'v1a'
      jsonObj.v1a.should.be.an.instanceOf(Array)
      jsonObj.v1a.should.have.lengthOf 2
      jsonObj.v1a[0].should.eql "hello"
      jsonObj.v1a[1].should.eql "hello2"
      done null

