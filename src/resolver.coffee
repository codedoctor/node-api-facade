_ = require 'underscore'
async = require 'async'

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


  resolve: (resolverMap, rootObject,options = {},client, cb = ->) =>
    console.log "OOO #{JSON.stringify(options)}"
    functions = []

    console.log "I NEED RESOLVE:"
    for kind,collection of @matrix
      resolver = resolverMap[kind]
      objectIds = _.keys(collection)
      if resolver && _.isArray(objectIds) && objectIds.length > 0
        functions.push (cb) => resolver.resolve kind,objectIds,options,cb

      console.log "Collection: #{kind}"
      for id in _.keys(collection)
        console.log "ID: #{id}"
    console.log "==============="

    if functions.length > 0
      async.parallel functions, (err,results) =>
        console.log "==========++++========="
        console.log "GOT RESULTS"

        for r in (results || [])
          r.items = r.items || []
          keys = _.keys(r.items)
          keys = _.filter keys, (x) => @embedMe[x]

          console.log JSON.stringify(r)
          console.log "-------"

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
            for o in t || []
              if r.items[id]
                options.scopes = ['inline']
                _.extend o, client.mapObjectSync(r.kind,r.items[id],options,null)

        cb err, rootObject

    else
      cb null, rootObject