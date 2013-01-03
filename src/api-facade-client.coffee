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
    return {} unless schema
    mappings = schema.mappings || {}
    filterScopes = schema.scopes || {}
    return mappings unless filterScopes && _.keys(filterScopes).length > 0

    scopes = options.scopes
    scopes = ['default'] if !scopes || (_.isArray(scopes) and scopes.length is 0)

    finalFields = {}
    for scopeKey,scopeValue of filterScopes when _.contains(scopes,scopeKey) && scopeValue.mode isnt 'restrict'
      finalFields[scope] = true for scope in (scopeValue.fields || {})

    for scopeKey,scopeValue of filterScopes when _.contains(scopes,scopeKey) &&  scopeValue.mode is 'restrict'
      for k of finalFields
        delete finalFields[k] if not _.contains( scopeValue.fields,k)

    resultMappings = {}
    for key,v of mappings when finalFields[key]
      resultMappings[key] = v

    resultMappings

  ###
  Not used right now - kept only to not break stuff - sorry.
  ###
  _isCollectionTypeList: (collectionType = '') =>
    collectionType.toLowerCase() is 'list'

  ###
  Determines if a collection type is of type 'array'
  ###
  _isCollectionTypeArray: (collectionType = '') =>
    collectionType.toLowerCase() is 'array'

  ###
  Determines if a collectiontype is of type 'list' or 'array'
  ###
  _isCollectionTypeListOrArray: (collectionType) =>
    @_isCollectionTypeList(collectionType) || @_isCollectionTypeArray(collectionType)


  _handleSingleMapping: (targetKey,mappingTarget,source,result,resolver,options = {}) =>
      if _.isString(mappingTarget)
        result[targetKey] = source[mappingTarget]
      else if _.isObject(mappingTarget)
        v = source[mappingTarget.name]

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
                  if mappingTarget.embed && mappingTarget.type
                    x = x # just a reminder
                    resolver.add mappingTarget.type,x,null,true if resolver
                    return x
                  else
                    return @mapObjectSync(mappingTarget.type,x,options,null)
                
                #for xx in v
                #  resolver.add mappingTarget.type,xx.id,xx,false if resolver && xx.id
                # TODO: Add url here too, add to resolver if necessary
              else
                v = _.first(v) if _.isArray(v)
                if v
                  if mappingTarget.embed && mappingTarget.type
                    v = v # just a reminder
                    resolver.add mappingTarget.type,v,null,true if resolver
                  else
                  #resolveId = v.id
                    v = @mapObjectSync(mappingTarget.type,v,options,null)
                  

                  #console.log "HERE XXX: #{resolveId}"
                  #resolver.add mappingTarget.type,resolveId,v,false if resolver && v.id
                    # TODO: Add url here too, add to resolver if necessary
                else
                  v = null

            #if resolve
            # resolve - Only means that we resolve the target type
          else # No type has been specified. This means that mapping is 1 for 1, except when we have a collection type and v is NOT an array
            v = [v] if @_isCollectionTypeListOrArray(mappingTarget.collectionType) and (not _.isArray(v))

        else
          ###
          In general we set the value to whatever is the default value. However, if there is
          no default value and we map this to a list or an array then we set the value to an
          empty array.
          ###
          v = mappingTarget.default
          if @_isCollectionTypeListOrArray(mappingTarget.collectionType) 
            v = []

        result[targetKey] = v

  ###
  Maps an object, whose type is specified by kind, to a REST representation
  This method excepts null values for obj, and returns null values as a result.
  Please note that resolver can be null
  ###
  mapObjectSync: (kind,obj,options = {},resolver) =>
    throw new errors.UnprocessableEntity('kind') unless kind
    return null unless obj

    schema = @resolveSchema(kind,options)
    return obj unless schema # Keep it untransformed for now.
    #throw new Error("Could not resolve schema '#{kind}' with options '#{JSON.stringify(options)}'") unless schema

    result = {}
    @_handleSingleMapping(objKey,target ,obj,result,resolver,options) for objKey,target of @mappingsFromSchema(schema,options)

    result

  mapRootCollection: (kind,pagedResult = {},options={},cb) =>
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
    throw new errors.UnprocessableEntity('cb') unless cb # Errors are NOT runtime errors
    throw new errors.UnprocessableEntity('kind') unless kind
    throw new errors.UnprocessableEntity('item') unless item

    resolver = new Resolver()

    result = @mapObjectSync(kind,item,options,resolver)

    resolver.resolve @resolvers,result,options,@,(err) =>
      cb null, result
