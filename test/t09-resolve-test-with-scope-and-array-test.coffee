should = require 'should'
_ = require 'underscore'

model = ->
  targetIds : "id001"

model2 = ->
  targetIds : ["id001", 'id002']

module.exports = class ResolverUsers
  constructor: () ->
    # Ususally have a link to persistent store here.
    @kinds = ['User'] # Supported types

  resolve: (kind,userIdsToRetrieve = [],options = {},cb) =>
    userIdsToRetrieve = _.uniq(userIdsToRetrieve)

    result = 
      kind : kind
      collectionName: 'users'
      items : {}

    if _.contains(userIdsToRetrieve,'id001')
      result.items['id001'] = 
        id: "id001"
        username: 'martin'
        password: 'secret'
        email: 'hello@world.com'
    cb null,result


describe 'WHEN resolving stuff', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "TypeA", 
    mappings:
      targets: 
        name : 'targetIds'
        type: 'User'
        collectionType: 'Array'
        resolve: true
        embed : false

  apiFacade.addSchema "User", 
    mappings:
      id : 'id'
      username: 'username'
      password: 'password'
      email: 'email' 
    scopes:
      inline:
        fields: ['id','username']

  apiFacade.registerResolver new ResolverUsers


  it 'IT should transform values', (done) ->
    apiFacade.mapRoot 'TypeA', model(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      console.log "I GOT: #{JSON.stringify(jsonObj)}"
      jsonObj.should.not.have.property 'targetIds'
      jsonObj.should.have.property 'targets'
      jsonObj.targets.should.have.lengthOf 1
      jsonObj.targets[0].should.have.property 'id'
      jsonObj.targets[0].should.have.property 'username'
      jsonObj.targets[0].should.not.have.property 'password'
      jsonObj.targets[0].should.not.have.property 'email'
      done null


  it 'IT should transform values', (done) ->
    apiFacade.mapRoot 'TypeA', model2(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      console.log "I GOT: #{JSON.stringify(jsonObj)}"
      jsonObj.should.not.have.property 'targetIds'
      jsonObj.should.have.property 'targets'
      jsonObj.targets.should.have.lengthOf 2
      jsonObj.targets[0].should.have.property 'id'
      jsonObj.targets[0].should.have.property 'username'
      jsonObj.targets[0].should.not.have.property 'password'
      jsonObj.targets[0].should.not.have.property 'email'
      jsonObj.targets[1].should.have.property 'id'
      jsonObj.targets[1].should.not.have.property 'username' # Because it is not resolved.
      jsonObj.targets[1].should.not.have.property 'password'
      jsonObj.targets[1].should.not.have.property 'email'
      done null

