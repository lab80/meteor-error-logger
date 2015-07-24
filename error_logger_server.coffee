REPETITIVE_ERRORS =
  "Connection timeout. No sockjs heartbeat received."
  "TypeError: Cannot read property 'invalidate' of undefined"
LOG_ROUTE = '/errorlog'
ERROR_FIELDS = ['errorType', 'ipAddress', 'location', 'browser', 'details']
ERROR_TYPE_TO_SUBJECT_GETTER =
  JS: (error) -> error.details.message
  MANUAL: (error) -> error.details.message
  AJAX: (error) -> error.details.xhrStatusText
  METEOR: (error) -> error.details.message

_isRepetitiveError = (error) ->
  _.has(REPETITIVE_ERRORS, error.details.message)

ErrorLogger =
  _collection: new Mongo.Collection('errorlogs')
  log: (request) ->
    error = null
    unless _.isEmpty(request.body)
      body = EJSON.parse(request.body)

      if body.errorType of ERROR_TYPE_TO_SUBJECT_GETTER
        error = _.pick(body, ERROR_FIELDS)

    return "EMPTY" if _.isEmpty(error)

    error.ipAddress = request.headers['x-forwarded-for'] or request.connection.remoteAddress
    error.timestamp = new Date()

    ErrorLogger._collection.insert(error)

    unless _isRepetitiveError(error)
      from = process.env.ERROR_EMAIL_FROM
      to = process.env.ERROR_EMAIL_TO
      if from and to
        text = EJSON.stringify(error, indent: true)
        subject = ERROR_TYPE_TO_SUBJECT_GETTER[error.errorType](error)
        subject = "[Front error] #{error.errorType}: #{subject}"
        Email.send(from: from, to: to, subject: subject, text: text)

    "#{error.errorType} OK"

bodyParser = Npm.require('body-parser')
errorRoute = Picker.filter((request, res) ->
  request.method is 'POST' and request.url is LOG_ROUTE
)

errorRoute.middleware(bodyParser.text(
  type: "text/ejson"
))

errorRoute.route(LOG_ROUTE, (params, request, response) ->
  response.end(ErrorLogger.log(request))
)
