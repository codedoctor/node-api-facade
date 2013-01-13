_ = require 'underscore'
async = require 'async'

###
Necessary to bypass nastynesses from libs like mongoose
###
convertToObject = (item) ->
  return item.toObject() if item.toObject && _.isFunction(item.toObject)
  item

module.exports = class Resolver
  constructor: () ->
    @matrix = {}
    @embedMe = {}

  normalizeName: (name) =>
    name = name.toLowerCase()


  add:(kind,idOrIds, target, embed = false) =>
    kind = @normalizeName(kind)
    return unless idOrIds

    idOrIds = [idOrIds] unless _.isArray(idOrIds)

    collection = @matrix[kind]
    collection = @matrix[kind] = {} unless collection
    for id in idOrIds
      if collection[id] 
        collection[id].push target
      else
        collection[id]=[target]

      @embedMe[id.toString()] = true if embed

  ###
  Closure needed for this one.
  ###
  _addResolverToFunctions: (resolverMap,options,kind,collection,functions) =>
    resolver = resolverMap[kind]
    objectIds = _.keys(collection)
    if resolver && _.isArray(objectIds) && objectIds.length > 0
      functions.push (cb) => 
        resolver.resolve kind,objectIds,options,cb

  resolve: (resolverMap, rootObject,options = {},client, cb = ->) =>
    functions = []

    @_addResolverToFunctions(resolverMap,options,
      kind,collection,functions) for kind,collection of @matrix


    if functions.length > 0
      async.parallel functions, (err,results) =>
        return cb err if err
        @_afterResolve results,rootObject,options,client,cb
    else
      cb null, rootObject


  _afterResolve: (results = [],rootObject,options,client,cb) =>
    for r in results
      r.items = r.items || {}

      for k,val of r.items
        r.items[k] = convertToObject(val)

      keys = _.keys(r.items)
      keys = _.filter keys, (x) => @embedMe[x]

            
      if keys.length > 0 #We only add this if we have keys to embed.
        rootObject._embedded = {} unless rootObject._embedded
        rootObject._embedded[r.collectionName] = {} unless rootObject._embedded[r.collectionName]
        # Here we transform the items and add them to the embedded collection.
        c = rootObject._embedded[r.collectionName]
        
        c[k] = client.mapObjectSync(r.kind,r.items[k],options,null) for k in keys

      ###
      We need to merge this back. Each r looks like
      r =
        kind: ...
        collectionName: 'users'
        items: {} where the index into the items is the string/lowercased object id
      ###
      for id,t of (@matrix[r.kind] || {})
        @_mergeObjectBack id,t,r.kind,r.items,options,client

    cb null, rootObject


  _mergeObjectBack: (objectId,mergeTargets = [],kind,itemsCollection = {},options,client) =>
    for targetObject in mergeTargets when !!targetObject
      if itemsCollection[objectId]

        options.scopes = ['inline']
        resolved = client.mapObjectSync(kind,itemsCollection[objectId],options,null)
        _.extend targetObject, resolved
