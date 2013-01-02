###
API Facade client
###

ApiFacadeClient = require('./api-facade-client')

module.exports =
  ApiFacadeClient: ApiFacadeClient
  client: (settings = {}) ->
    new ApiFacadeClient(settings)
