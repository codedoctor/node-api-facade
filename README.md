node-api-facade
===========================

npm install api-facade

## About

A library that simplifies the exposure of data through REST interfaces in a secure, scope dependent way. Basically transforms internal data into whatever a client of your API has the right to see.

### Where does it fit in?

In general this should be the last step in a request pipeline before rendering objects to the client. An example would be

```coffeescript
      @apiFacade.mapRoot 'User', item, {baseUrl: @baseUrl, scopes:req.scopes}, (err,jsonObj) =>
          res.json jsonObj 
```

where apiFacade is the instantiated apiFacade object (which contains all the schema definitions)


### Features
* Agnostic towards the data model
* Can resolve relationships and extend objects (Think instagram adding user data when making an API request.)
* Fast enough. There is a lot of room for optimizations, but it is fast enough for our purposes.
* Resolvers are extensible
* Used in real projects (with 30K+ lines of node code).
* Supports scopes

### More
Resonable documentation will be written when I have a bit more time.

## Release Notes
### 0.2.2
* Added support for fn mapping. No docs or tests yet, but works like this:

```coffeescript
    mappings:
      url: 
        fn: (self,options) -> "#{options.baseUrl}/products/#{self._id}"
```
Using self for clarity. Thought it might be easier then mapping this.

### 0.2.1
* Added support for default scope if none is present. E.g. define a default scope, which is used if options.scopes is null or contains nothing.
### 0.2.0
* First version



## Internal Stuff

* npm run-script watch

## Publish new version

* Change version in package.json
git add . -A
git commit -m "Upgrading to v0.2.2"
git tag -a v0.2.2 -m 'version 0.2.2'
git push --tags
npm publish

## Contributing to node-api-facade
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it
* Fork the project
* Start a feature/bugfix branch
* Commit and push until you are happy with your contribution
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the package.json, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2013 Martin Wawrusch See LICENSE for
further details.

## Todo
* publish to npm
* Handle Url + Link case
