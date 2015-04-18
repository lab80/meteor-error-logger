LOG_ROUTE = '/errorlog'
ERROR_FIELDS = ['errorType', 'ipAddress', 'location', 'browser', 'details']
ERROR_TYPE_TO_SUBJECT_GETTER =
  JS: (error) -> error.details.message
  MANUAL: (error) -> error.details.message
  AJAX: (error) -> error.details.xhrStatusText

ErrorLogger =
  _collection: new Mongo.Collection('errorlogs')
  log: (request) ->
    error = null
    unless _.isEmpty(request.body)
      body = _.keys(request.body)[0]
      body = EJSON.parse(body)

      if body.errorType of ERROR_TYPE_TO_SUBJECT_GETTER
        error = _.pick(body, ERROR_FIELDS)

    return "EMPTY" if _.isEmpty(error)

    error.ipAddress = request.headers['x-forwarded-for'] or request.connection.remoteAddress
    error.timestamp = new Date()
    ErrorLogger._collection.insert(error)

    from = process.env.ERROR_EMAIL_FROM
    to = process.env.ERROR_EMAIL_TO
    if from and to
      text = EJSON.stringify(error, indent: true)
      subject = ERROR_TYPE_TO_SUBJECT_GETTER[error.errorType](error)
      subject = "[Front error] #{error.errorType}: #{subject}"
      Email.send(from: from, to: to, subject: subject, text: text)
    "#{error.errorType} OK"

Router.map(->
  @route('errorlog', path: LOG_ROUTE, where: 'server')
    .post(->
      @response.end(ErrorLogger.log(@request))
    )
)
