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
      targetId: 
        name : 'targetId'
        type: 'User'
        embed : true
        resolve: false

  apiFacade.addSchema "User", 
    mappings:
      id : 'id'
      username: 'username'
      password: 'password'
      email: 'email' 
    scopes:
      inline:
        fields: ['id','username']
      scopea:
        fields: ['id','username','email']

  apiFacade.registerResolver new ResolverUsers


  it 'IT should transform values', (done) ->
    apiFacade.mapRoot 'TypeA', model(), scopes: ['scopea'], (err,jsonObj) ->
      console.log "I GOT: #{JSON.stringify(jsonObj)}"
      should.not.exist err
      should.exist jsonObj
      jsonObj.should.have.property 'targetId','id001'

      jsonObj.should.have.property '_embedded'
      jsonObj._embedded.should.have.property 'users'
      jsonObj._embedded.users.should.have.property 'id001'
      jsonObj._embedded.users.id001.should.have.property 'id'
      jsonObj._embedded.users.id001.should.have.property 'username'
      jsonObj._embedded.users.id001.should.not.have.property 'password'
      jsonObj._embedded.users.id001.should.have.property 'email'
      done null


