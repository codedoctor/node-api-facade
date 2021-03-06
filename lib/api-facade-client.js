// Generated by CoffeeScript 1.4.0
(function() {
  var ApiFacadeClient, Resolver, errors, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  errors = require('some-errors');

  Resolver = require('./resolver');

  module.exports = ApiFacadeClient = (function() {

    function ApiFacadeClient(settings) {
      this.settings = settings != null ? settings : {};
      this.mapRoot = __bind(this.mapRoot, this);

      this.mapRootCollection = __bind(this.mapRootCollection, this);

      this.mapObjectSync = __bind(this.mapObjectSync, this);

      this._handleSingleMapping = __bind(this._handleSingleMapping, this);

      this._invokeFnMapping = __bind(this._invokeFnMapping, this);

      this._isCollectionTypeListOrArray = __bind(this._isCollectionTypeListOrArray, this);

      this._isCollectionTypeArray = __bind(this._isCollectionTypeArray, this);

      this._isCollectionTypeList = __bind(this._isCollectionTypeList, this);

      this.mappingsFromSchema = __bind(this.mappingsFromSchema, this);

      this.resolveSchema = __bind(this.resolveSchema, this);

      this.addSchema = __bind(this.addSchema, this);

      this.registerResolver = __bind(this.registerResolver, this);

      this.normalizeName = __bind(this.normalizeName, this);

      _.defaults(this.settings, {});
      this.schemas = {};
      this.defaultMappings = {};
      this.resolvers = {};
    }

    ApiFacadeClient.prototype.normalizeName = function(name) {
      return name = name.toLowerCase();
    };

    ApiFacadeClient.prototype.registerResolver = function(resolver) {
      var kind, _i, _len, _ref, _results;
      if (!resolver) {
        throw new errors.UnprocessableEntity('resolver');
      }
      _ref = resolver.kinds;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        kind = _ref[_i];
        kind = this.normalizeName(kind);
        _results.push(this.resolvers[kind] = resolver);
      }
      return _results;
    };

    ApiFacadeClient.prototype.addSchema = function(kind, schema) {
      if (schema == null) {
        schema = {};
      }
      if (!kind) {
        throw new errors.UnprocessableEntity('kind');
      }
      kind = this.normalizeName(kind);
      if (!schema.mappings) {
        schema.mappings = {};
      }
      this.schemas[kind] = schema;
      return this;
    };

    /*
      Returns the schema for a type.
    */


    ApiFacadeClient.prototype.resolveSchema = function(kind, options) {
      if (options == null) {
        options = {};
      }
      kind = this.normalizeName(kind);
      return this.schemas[kind];
    };

    /*
      Returns the mapping for a schema. Looks for options.scopes
    */


    ApiFacadeClient.prototype.mappingsFromSchema = function(schema, options) {
      var filterScopes, finalFields, k, key, mappings, resultMappings, scope, scopeKey, scopeValue, scopes, v, _i, _len, _ref;
      if (options == null) {
        options = {};
      }
      if (!schema) {
        return {};
      }
      mappings = schema.mappings || {};
      filterScopes = schema.scopes || {};
      if (!(filterScopes && _.keys(filterScopes).length > 0)) {
        return mappings;
      }
      scopes = options.scopes;
      if (!scopes || (_.isArray(scopes) && scopes.length === 0)) {
        scopes = ['default'];
      }
      finalFields = {};
      for (scopeKey in filterScopes) {
        scopeValue = filterScopes[scopeKey];
        if (_.contains(scopes, scopeKey) && scopeValue.mode !== 'restrict') {
          _ref = scopeValue.fields || {};
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            scope = _ref[_i];
            finalFields[scope] = true;
          }
        }
      }
      for (scopeKey in filterScopes) {
        scopeValue = filterScopes[scopeKey];
        if (_.contains(scopes, scopeKey) && scopeValue.mode === 'restrict') {
          for (k in finalFields) {
            if (!_.contains(scopeValue.fields, k)) {
              delete finalFields[k];
            }
          }
        }
      }
      resultMappings = {};
      for (key in mappings) {
        v = mappings[key];
        if (finalFields[key]) {
          resultMappings[key] = v;
        }
      }
      return resultMappings;
    };

    /*
      Not used right now - kept only to not break stuff - sorry.
    */


    ApiFacadeClient.prototype._isCollectionTypeList = function(collectionType) {
      if (collectionType == null) {
        collectionType = '';
      }
      return collectionType.toLowerCase() === 'list';
    };

    /*
      Determines if a collection type is of type 'array'
    */


    ApiFacadeClient.prototype._isCollectionTypeArray = function(collectionType) {
      if (collectionType == null) {
        collectionType = '';
      }
      return collectionType.toLowerCase() === 'array';
    };

    /*
      Determines if a collectiontype is of type 'list' or 'array'
    */


    ApiFacadeClient.prototype._isCollectionTypeListOrArray = function(collectionType) {
      return this._isCollectionTypeList(collectionType) || this._isCollectionTypeArray(collectionType);
    };

    ApiFacadeClient.prototype._invokeFnMapping = function(fn, source, options) {
      if (options == null) {
        options = {};
      }
      return fn(source, options);
    };

    ApiFacadeClient.prototype._handleSingleMapping = function(targetKey, mappingTarget, source, result, resolver, options) {
      var idField, v,
        _this = this;
      if (options == null) {
        options = {};
      }
      if (_.isString(mappingTarget)) {
        return result[targetKey] = source[mappingTarget];
      } else if (_.isObject(mappingTarget)) {
        v = source[mappingTarget.name];
        if (mappingTarget.fn && _.isFunction(mappingTarget.fn)) {
          result[targetKey] = this._invokeFnMapping(mappingTarget.fn, source, options);
          return;
        }
        if (v) {
          if (mappingTarget.type) {
            if (mappingTarget.resolve) {
              /*
                            Having a target type means that we need to transpose this into an object or an array of objects.
              */

              if (this._isCollectionTypeListOrArray(mappingTarget.collectionType)) {
                if (!_.isArray(v)) {
                  v = [v];
                }
                v = _.map(v, function(x) {
                  var r;
                  r = {
                    id: x
                  };
                  if (resolver) {
                    resolver.add(mappingTarget.type, x, r, mappingTarget.embed);
                  }
                  return r;
                });
              } else {
                if (_.isArray(v)) {
                  v = _.first(v);
                }
                if (v) {
                  v = {
                    id: v
                  };
                  if (resolver) {
                    resolver.add(mappingTarget.type, v.id, v, mappingTarget.embed);
                  }
                } else {
                  v = null;
                }
              }
            } else if (mappingTarget.resolveInPlace) {
              idField = "_id";
              if (mappingTarget['idField']) {
                idField = mappingTarget['idField'];
              }
              if (resolver) {
                resolver.add(mappingTarget.type, v[idField], v, mappingTarget.embed);
              }
            } else {
              if (this._isCollectionTypeListOrArray(mappingTarget.collectionType)) {
                if (!_.isArray(v)) {
                  v = [v];
                }
                v = _.map(v, function(x) {
                  if (mappingTarget.embed && mappingTarget.type) {
                    x = x;
                    if (resolver) {
                      resolver.add(mappingTarget.type, x, null, true);
                    }
                    return x;
                  } else {
                    return _this.mapObjectSync(mappingTarget.type, x, options, null);
                  }
                });
              } else {
                if (_.isArray(v)) {
                  v = _.first(v);
                }
                if (v) {
                  if (mappingTarget.embed && mappingTarget.type) {
                    v = v;
                    if (resolver) {
                      resolver.add(mappingTarget.type, v, null, true);
                    }
                  } else {
                    v = this.mapObjectSync(mappingTarget.type, v, options, null);
                  }
                } else {
                  v = null;
                }
              }
            }
          } else {
            if (this._isCollectionTypeListOrArray(mappingTarget.collectionType) && (!_.isArray(v))) {
              v = [v];
            }
          }
        } else {
          /*
                    In general we set the value to whatever is the default value. However, if there is
                    no default value and we map this to a list or an array then we set the value to an
                    empty array.
          */

          v = mappingTarget["default"];
          if (this._isCollectionTypeListOrArray(mappingTarget.collectionType)) {
            v = [];
          }
        }
        return result[targetKey] = v;
      }
    };

    /*
      Maps an object, whose type is specified by kind, to a REST representation
      This method excepts null values for obj, and returns null values as a result.
      Please note that resolver can be null
    */


    ApiFacadeClient.prototype.mapObjectSync = function(kind, obj, options, resolver) {
      var objKey, result, schema, target, _ref;
      if (options == null) {
        options = {};
      }
      if (!kind) {
        throw new errors.UnprocessableEntity('kind');
      }
      if (!obj) {
        return null;
      }
      schema = this.resolveSchema(kind, options);
      if (!schema) {
        return obj;
      }
      result = {};
      _ref = this.mappingsFromSchema(schema, options);
      for (objKey in _ref) {
        target = _ref[objKey];
        this._handleSingleMapping(objKey, target, obj, result, resolver, options);
      }
      return result;
    };

    ApiFacadeClient.prototype.mapRootCollection = function(kind, pagedResult, options, cb) {
      var resolver, result,
        _this = this;
      if (pagedResult == null) {
        pagedResult = {};
      }
      if (options == null) {
        options = {};
      }
      if (!cb) {
        throw new errors.UnprocessableEntity('cb');
      }
      if (!kind) {
        throw new errors.UnprocessableEntity('kind');
      }
      if (!pagedResult) {
        throw new errors.UnprocessableEntity('pagedResult');
      }
      resolver = new Resolver();
      result = {
        totalCount: pagedResult.totalCount || 0,
        requestOffset: pagedResult.requestOffset || 0,
        requestCount: pagedResult.requestCount || 0,
        items: _.map(pagedResult.items || [], function(x) {
          return _this.mapObjectSync(kind, x, options, resolver);
        })
      };
      result;

      return resolver.resolve(this.resolvers, result, options, this, function(err) {
        return cb(null, result);
      });
    };

    ApiFacadeClient.prototype.mapRoot = function(kind, item, options, cb) {
      var resolver, result,
        _this = this;
      if (item == null) {
        item = {};
      }
      if (options == null) {
        options = {};
      }
      if (!cb) {
        throw new errors.UnprocessableEntity('cb');
      }
      if (!kind) {
        throw new errors.UnprocessableEntity('kind');
      }
      if (!item) {
        throw new errors.UnprocessableEntity('item');
      }
      resolver = new Resolver();
      result = this.mapObjectSync(kind, item, options, resolver);
      return resolver.resolve(this.resolvers, result, options, this, function(err) {
        return cb(null, result);
      });
    };

    return ApiFacadeClient;

  })();

}).call(this);
