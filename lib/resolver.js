// Generated by CoffeeScript 1.4.0
(function() {
  var Resolver, async, _,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  _ = require('underscore');

  async = require('async');

  module.exports = Resolver = (function() {

    function Resolver() {
      this.resolve = __bind(this.resolve, this);

      this.add = __bind(this.add, this);

      this.normalizeName = __bind(this.normalizeName, this);
      this.matrix = {};
      this.embedMe = {};
    }

    Resolver.prototype.normalizeName = function(name) {
      return name = name.toLowerCase();
    };

    Resolver.prototype.add = function(kind, idOrIds, target, embed) {
      var collection, id, _i, _len, _results;
      if (embed == null) {
        embed = false;
      }
      kind = this.normalizeName(kind);
      if (!idOrIds) {
        return;
      }
      if (!_.isArray(idOrIds)) {
        idOrIds = [idOrIds];
      }
      collection = this.matrix[kind];
      if (!collection) {
        collection = this.matrix[kind] = {};
      }
      _results = [];
      for (_i = 0, _len = idOrIds.length; _i < _len; _i++) {
        id = idOrIds[_i];
        if (collection[id]) {
          collection[id].push(target);
        } else {
          collection[id] = [target];
        }
        if (embed) {
          _results.push(this.embedMe[id.toString()] = true);
        } else {
          _results.push(void 0);
        }
      }
      return _results;
    };

    Resolver.prototype.resolve = function(resolverMap, rootObject, options, client, cb) {
      var collection, functions, id, kind, objectIds, resolver, _i, _len, _ref, _ref1,
        _this = this;
      if (options == null) {
        options = {};
      }
      if (cb == null) {
        cb = function() {};
      }
      console.log("OOO " + (JSON.stringify(options)));
      functions = [];
      console.log("I NEED RESOLVE:");
      _ref = this.matrix;
      for (kind in _ref) {
        collection = _ref[kind];
        resolver = resolverMap[kind];
        objectIds = _.keys(collection);
        if (resolver && _.isArray(objectIds) && objectIds.length > 0) {
          functions.push(function(cb) {
            return resolver.resolve(kind, objectIds, options, cb);
          });
        }
        console.log("Collection: " + kind);
        _ref1 = _.keys(collection);
        for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
          id = _ref1[_i];
          console.log("ID: " + id);
        }
      }
      console.log("===============");
      if (functions.length > 0) {
        return async.parallel(functions, function(err, results) {
          var c, k, keys, o, r, t, _j, _k, _l, _len1, _len2, _len3, _ref2, _ref3, _ref4;
          console.log("==========++++=========");
          console.log("GOT RESULTS");
          _ref2 = results || [];
          for (_j = 0, _len1 = _ref2.length; _j < _len1; _j++) {
            r = _ref2[_j];
            r.items = r.items || [];
            keys = _.keys(r.items);
            keys = _.filter(keys, function(x) {
              return _this.embedMe[x];
            });
            console.log(JSON.stringify(r));
            console.log("-------");
            if (keys.length > 0) {
              if (!rootObject._embedded) {
                rootObject._embedded = {};
              }
              if (!rootObject._embedded[r.collectionName]) {
                rootObject._embedded[r.collectionName] = {};
              }
              c = rootObject._embedded[r.collectionName];
              for (_k = 0, _len2 = keys.length; _k < _len2; _k++) {
                k = keys[_k];
                c[k] = client.mapObjectSync(r.kind, r.items[k], options, null);
              }
            }
            /*
                      We need to merge this back. Each r looks like
                      r =
                        kind: ...
                        collectionName: 'users'
                        items: {} where the index into the items is the string/lowercased object id
            */

            _ref3 = _this.matrix[r.kind] || {};
            for (id in _ref3) {
              t = _ref3[id];
              _ref4 = t || [];
              for (_l = 0, _len3 = _ref4.length; _l < _len3; _l++) {
                o = _ref4[_l];
                if (r.items[id]) {
                  options.scopes = ['inline'];
                  _.extend(o, client.mapObjectSync(r.kind, r.items[id], options, null));
                }
              }
            }
          }
          return cb(err, rootObject);
        });
      } else {
        return cb(null, rootObject);
      }
    };

    return Resolver;

  })();

}).call(this);