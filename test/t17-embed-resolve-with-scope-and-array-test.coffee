should = require 'should'
_ = require 'underscore'

model = ->
  targetIds : ["id001","id002"]


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
        emaila: 'hello@world.com' # Important: Name is emaila to test mapping and scope
    cb null,result


describe 'WHEN resolving stuff', ->
  index = require '../lib/index'
  apiFacade = index.client()
  apiFacade.addSchema "TypeA", 
    mappings:
      targets: 
        name : 'targetIds'
        type: 'User'
        embed : true
        resolve: true
        collectionType: 'Array'

  apiFacade.addSchema "User", 
    mappings:
      id : 'id'
      username: 'username'
      password: 'password'
      email: 'emaila' 
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
      jsonObj.should.have.property 'targets'
      jsonObj.targets.should.have.lengthOf 2

      jsonObj.targets[0].should.have.property 'id','id001'
      jsonObj.targets[0].should.have.property 'username','martin'
      jsonObj.targets[0].should.not.have.property 'password'
      jsonObj.targets[0].should.not.have.property 'email'

      jsonObj.targets[1].should.have.property 'id','id002'
      jsonObj.targets[1].should.not.have.property 'username'
      jsonObj.targets[1].should.not.have.property 'password'
      jsonObj.targets[1].should.not.have.property 'email'

      jsonObj.should.have.property '_embedded'
      jsonObj._embedded.should.have.property 'users'
      jsonObj._embedded.users.should.have.property 'id001'
      jsonObj._embedded.users.id001.should.have.property 'id','id001'
      jsonObj._embedded.users.id001.should.have.property 'username','martin'
      jsonObj._embedded.users.id001.should.not.have.property 'password'
      jsonObj._embedded.users.id001.should.have.property 'email','hello@world.com'
      done null


