LOG_ROUTE = '/errorlog'

ErrorLogger =
  init: ->
    # This catches all uncaught errors in javascript code (TypeError, etc.)
    self = this

    #Set requestSentTime to calculate how long an AJAX request takes
    $.ajaxSetup(
      beforeSend: (xhr, settings) ->
        settings.requestSentTime = Date.now()
    )

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
      log = JSON.stringify(log)
      $.post(LOG_ROUTE, log, (resp) ->
        console.log "JS_LOG_OK"
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
          xhrResponseText: xhr.responseText
          xhrStatusText: "#{xhr.status} #{xhr.statusText}"
          url: settings.url
          data: settings.data,
          responseHeaders: xhr.getAllResponseHeaders()
          responseTime: responseTime

      log = JSON.stringify(log)
      $.post(LOG_ROUTE, log, (resp) ->
        console.log "AJAX_LOG_OK"
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
    log = JSON.stringify(log)
    $.post(LOG_ROUTE, log, (resp) ->
      console.log "MANUAL_LOG_OK"
    )

  getBrowserData: ->
    browserData =
      UA: navigator.userAgent
      platform: navigator.platform
      language: navigator.language
      cookieEnabled: navigator.cookieEnabled

Meteor.startup(->
  ErrorLogger.init()
)
