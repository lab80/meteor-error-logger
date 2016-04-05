LOG_ROUTE = '/errorlog'
_stackRegex = /^\s+at\s.+$/gm
_getStackFromMessage = (message) ->
  # add empty string to add the empty line at start
  stack = ['']
  while (match = _stackRegex.exec(message))
    stack.push(match[0])
  stack.join('\n')
_firstLine = (message) -> _.first(message.split('\n'))

ErrorLogger =
  init: ->
    # This catches all uncaught errors in javascript code (TypeError, etc.)
    self = this

    #Set requestSentTime to calculate how long an AJAX request takes
    $.ajaxSetup(
      beforeSend: (xhr, settings) ->
        settings.requestSentTime = Date.now()
    )

    unless Meteor.settings?.public?.preserveMeteorDebug
      _originalMeteorDebug = Meteor._debug
      Meteor._debug = (message, stack) ->
        if message instanceof Error
          stack = message.stack
          message = message.message
        else if (_.isString(message) or message) and _.isUndefined(stack)
          stack = _getStackFromMessage(message)
          message = _firstLine(message)

        log =
          errorType: 'METEOR'
          browser: self.getBrowserData()
          location: location.href
          details:
            message: message
            stack: stack
        self._postLog(log, (err, resp) ->
          console.log if err then err else "METEOR_LOG_OK"
        )
        _originalMeteorDebug.apply(this, arguments)

    window.onerror = (message, file, line, column, error) ->
      # Ignore if msg is the following
      if (message.trim() == 'Script error.') then return
      log =
        errorType: 'JS'
        browser: self.getBrowserData()
        location: location.href
        details:
          message: message
          fileName: file
          lineNumber: line
          columnNumber: column
          stack: error.stack
      self._postLog(log, (err, resp) ->
        console.log if err then err else "JS_LOG_OK"
      )

    # This catches all errors in ajax calls
    $(document).ajaxError((event, xhr, settings, error) ->
      return if self._isIgnoredUrl(settings.url)
      responseTime = (Date.now() - settings.requestSentTime) / 1000

      log =
        errorType: 'AJAX'
        browser: self.getBrowserData()
        location: location.href
        details:
          message: xhr.responseText
          xhrResponseText: xhr.responseText
          xhrStatusText: "#{xhr.status} #{xhr.statusText}"
          url: settings.url
          data: settings.data,
          responseHeaders: xhr.getAllResponseHeaders()
          responseTime: responseTime

      self._postLog(log, (err, resp) ->
        console.log if err then err else "AJAX_LOG_OK"
      )
    )

  _isIgnoredUrl: (url) ->
    return (
      url.indexOf(LOG_ROUTE) != -1 or
      url.indexOf('kadira.io') != -1
    )

  manualLog: (message) ->
    log =
      errorType: 'MANUAL'
      browser: @getBrowserData()
      location: location.href
      details:
        message: message
    @_postLog(log, (err, resp) ->
      # DEBUG LINE
      # console.log log
      console.log if err then err else "MANUAL_LOG_OK"
    )

  _postLog: (log, callback) ->
    logString = JSON.stringify(log)
    headers =
      "Content-Type": "text/ejson"

    HTTP.post(LOG_ROUTE, {
      content: logString
      headers: headers,
    }, (err, res) ->
      callback(err, res) if callback
    )

  getBrowserData: ->
    ua = new window.UAParser()
    browserData = _.extend(ua.getResult(),
      platform: navigator.platform
      language: navigator.language
      cookieEnabled: navigator.cookieEnabled
    )

Meteor.startup(->
  ErrorLogger.init()
)
