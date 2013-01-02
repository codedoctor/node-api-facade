_ = require 'underscore'
errors = require 'some-errors'
Resolver = require './resolver'

module.exports = class ApiFacadeClient
  constructor: (@settings = {}) ->
    _.defaults @settings, {}
    @schemas = {}
    @defaultMappings = {}
    @resolvers = {}

  normalizeName: (name) =>
    name = name.toLowerCase()

  registerResolver: (resolver) =>
    throw new errors.UnprocessableEntity('resolver') unless resolver
    for kind in resolver.kinds
      kind = @normalizeName(kind)
      @resolvers[kind] = resolver



  addSchema: (kind,schema = {}) =>
    throw new errors.UnprocessableEntity('kind') unless kind
    kind = @normalizeName kind
    schema.mappings = {} unless schema.mappings
    schema.filters = {} unless schema.filters

    @schemas[kind] = schema
    @


  ###
  Returns the schema for a type. 
  ###
  resolveSchema: (kind,options =  {}) =>
    kind = @normalizeName kind
    @schemas[kind]

  ###
  Returns the mapping for a schema. Looks for options.scopes
  ###
  mappingsFromSchema: (schema,options = {}) =>
    console.log "OPTIONS: #{JSON.stringify(options)}"
    return {} unless schema
    mappings = schema.mappings || {}
    filterScopes = schema.filters?.scopes || {}
    return mappings unless filterScopes && _.keys(filterScopes).length > 0

    console.log "FILTERSCOPES #{JSON.stringify(filterScopes)}"
    finalFields = {}
    for filterKey,filterValue of filterScopes
      if _.contains(options.scopes,filterKey)
        _.extend( finalFields, filterValue.fields || {})

    resultMappings = {}
    for key,v of mappings when finalFields[key]
      resultMappings[key] = v

    resultMappings

  _isCollectionTypeList: (collectionType = '') =>
    collectionType.toLowerCase() is 'list'

  _isCollectionTypeArray: (collectionType = '') =>
    collectionType.toLowerCase() is 'array'

  _isCollectionTypeListOrArray: (collectionType) =>
    @_isCollectionTypeList(collectionType) || @_isCollectionTypeArray(collectionType)

  _handleSingleMapping: (sourceKey,mappingTarget,source,result,resolver,options = {}) =>
      options = {} # Temp
      if _.isString(mappingTarget)
        result[mappingTarget] = source[sourceKey]
      else if _.isObject(mappingTarget)
        name = mappingTarget.name || sourceKey

        v = source[sourceKey]

        if v
          if mappingTarget.type

            if mappingTarget.resolve
              ###
              Having a target type means that we need to transpose this into an object or an array of objects.
              ###

              if @_isCollectionTypeListOrArray(mappingTarget.collectionType)
                v = [v] unless _.isArray(v)
                v = _.map v, (x) =>
                  r = {id : x}
                  resolver.add mappingTarget.type,x,r,mappingTarget.embed if resolver
                  r
                  
                # TODO: Add url here too, add to resolver if necessary
              else
                v = _.first(v) if _.isArray(v)
                if v
                  v = 
                    id: v
                  resolver.add mappingTarget.type,v.id,v,mappingTarget.embed if resolver
                    # TODO: Add url here too, add to resolver if necessary
                else
                  v = null
            else if mappingTarget.resolveInPlace
              # This means that we have an object here that is incomplete. created By comes to mind
              idField = "_id"
              idField = mappingTarget['idField'] if mappingTarget['idField'] 
              resolver.add mappingTarget.type,v[idField],v,mappingTarget.embed if resolver

            else # Do not resolve. This means that we have native objects stored here.
              if @_isCollectionTypeListOrArray(mappingTarget.collectionType)
                v = [v] unless _.isArray(v)
                v = _.map v, (x) =>
                  return @mapObjectSync(mappingTarget.type,x,options,null)
                  
                # TODO: Add url here too, add to resolver if necessary
              else
                v = _.first(v) if _.isArray(v)
                if v
                  v = @mapObjectSync(mappingTarget.type,v,options,null)
                    # TODO: Add url here too, add to resolver if necessary
                else
                  v = null

            #if resolve
            # resolve - Only means that we resolve the target type


        else
          ###
          In general we set the value to whatever is the default value. However, if there is
          no default value and we map this to a list or an array then we set the value to an
          empty array.
          ###
          v = mappingTarget.default
          if @_isCollectionTypeListOrArray(mappingTarget.collectionType) 
            v = []

        result[name] = v
      else if _.isArray(mappingTarget)
        @_handleSingleMapping(sourceKey,mt,source,result,null,options) for mt in mappingTarget

  ###
  Maps an object, whose type is specified by kind, to a REST representation
  This method excepts null values for obj, and returns null values as a result.
  Please note that resolver can be null
  ###
  mapObjectSync: (kind,obj,options = {},resolver) =>
    console.log "KIND #{kind} #{JSON.stringify(options)}"
    throw new errors.UnprocessableEntity('kind') unless kind
    return null unless obj

    schema = @resolveSchema(kind,options)
    return obj unless schema # Keep it untransformed for now.
    #throw new Error("Could not resolve schema '#{kind}' with options '#{JSON.stringify(options)}'") unless schema

    result = {}
    @_handleSingleMapping(objKey,target ,obj,result,resolver,options) for objKey,target of @mappingsFromSchema(schema)

    result

  mapRootCollection: (kind,pagedResult = {},options={},cb) =>
    console.log "MAP ROOT COLLECTION: #{JSON.stringify(options)}"
    throw new errors.UnprocessableEntity('cb') unless cb # Errors are NOT runtime errors
    throw new errors.UnprocessableEntity('kind') unless kind
    throw new errors.UnprocessableEntity('pagedResult') unless pagedResult

    resolver = new Resolver()

    result =
      totalCount : pagedResult.totalCount || 0
      requestOffset : pagedResult.requestOffset  || 0
      requestCount : pagedResult.requestCount || 0
      items : _.map( pagedResult.items || [], (x) => @mapObjectSync(kind,x,options,resolver) )
    result

    resolver.resolve @resolvers,result,options,@,(err) =>
      cb null, result

  mapRoot: (kind,item = {},options={},cb) =>
    console.log "MAP ROOT: #{JSON.stringify(options)}"
    throw new errors.UnprocessableEntity('cb') unless cb # Errors are NOT runtime errors
    throw new errors.UnprocessableEntity('kind') unless kind
    throw new errors.UnprocessableEntity('item') unless item

    resolver = new Resolver()

    result = @mapObjectSync(kind,item,options,resolver)

    resolver.resolve @resolvers,result,options,@,(err) =>
      cb null, result