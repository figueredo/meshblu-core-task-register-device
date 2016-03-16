_              = require 'lodash'
mongojs        = require 'mongojs'
Datastore      = require 'meshblu-core-datastore'
Cache          = require 'meshblu-core-cache'
redis          = require 'fakeredis'
uuid           = require 'uuid'
RegisterDevice = require '../'

describe 'RegisterDevice', ->
  beforeEach (done) ->
    @datastore = new Datastore
      database: mongojs 'subscription-manager-test'
      collection: 'subscriptions'

    @datastore.remove done

  beforeEach ->
    @cache = new Cache client: redis.createClient uuid.v1()
    @sut = new RegisterDevice {@datastore, @cache}

  describe '->do', ->
    describe 'when given a valid request', ->
      beforeEach (done) ->
        request =
          metadata:
            responseId: 'its-electric'
            uuid: 'electric-eels'
            messageType: 'received'
            options: {}
          rawData: '{"type":"holly-molly"}'

        @sut.do request, (error, @response) => done error

      it 'should return you a device with the uuid and token', ->
        expect(@response.data.uuid).to.exist
        expect(@response.data.token).to.exist

      it 'should have a device and all of the base properties', (done) ->
        @datastore.findOne {uuid: @response.data.uuid}, (error, device) =>
          return done error if error?
          expect(device.type).to.equal 'holly-molly'
          expect(device.online).to.be.false
          expect(device.uuid).to.exist
          expect(device.token).to.exist
          expect(device.meshblu.createdAt).to.exist
          expect(device.meshblu.hash).to.exist
          done()

      it 'should create the token in the cache', (done) ->
        @datastore.findOne {uuid: @response.data.uuid}, (error, device) =>
          return done error if error?
          @cache.exists "meshblu-token-cache:#{device.uuid}:#{device.token}", (error, result) =>
            return done error if error?
            expect(result).to.be.true
            done()

      it 'should return a 204', ->
        expectedResponseMetadata =
          responseId: 'its-electric'
          code: 201
          status: 'Created'

        expect(@response.metadata).to.deep.equal expectedResponseMetadata
