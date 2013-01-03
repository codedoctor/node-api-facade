should = require 'should'
_ = require 'underscore'

model = ->
  targetId : "id001"


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
      target: 
        name : 'targetId'
        type: 'User'
        resolve: true
        embed : false

  apiFacade.addSchema "User", 
    mappings:
      id : 'id'
      username: 'username'
      password: 'password'
      email: 'email' 

  apiFacade.registerResolver new ResolverUsers


  it 'IT should transform values', (done) ->
    apiFacade.mapRoot 'TypeA', model(), {}, (err,jsonObj) ->
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.not.have.property 'targetId'
      jsonObj.should.have.property 'target'
      jsonObj.target.should.have.property 'id'
      jsonObj.target.should.have.property 'username'
      jsonObj.target.should.have.property 'password'
      jsonObj.target.should.have.property 'email'
      done null


