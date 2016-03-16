_             = require 'lodash'
http          = require 'http'
DeviceManager = require 'meshblu-core-manager-device'

class RegisterDevice
  constructor: ({@cache,@uuidAliasResolver,@datastore}) ->
    throw new Error "Missing mandatory @cache option" unless @cache?
    throw new Error "Missing mandatory @datastore option" unless @datastore?
    @deviceManager = new DeviceManager {@cache, @datastore}

  _doCallback: (request, code, device, callback) =>
    response =
      metadata:
        responseId: request.metadata.responseId
        code: code
        status: http.STATUS_CODES[code]
      data: device
    callback null, response

  do: (request, callback) =>
    properties = JSON.parse request.rawData
    @deviceManager.create properties, (error, device) =>
      return callback error if error?
      return @_doCallback request, 201, device, callback

module.exports = RegisterDevice
