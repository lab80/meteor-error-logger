# Meteor Client-side Error Logger

Simple client-side error logger for Meteor. The package works out of the box and
logs uncaught front-end JS errors, AJAX errors, and custom errors to Mongo.

To install:

```sh
$ meteor add lab80:error-logger
```

## Customization

To have it send emails for each error, set the `ERROR_EMAIL_FROM` and
`ERROR_EMAIL_TO` environment variables.

To log a custom error:

```js
ErrorLogger.manualLog("your message here")
```

## Prevent from sending email for certain errors

To prevent it from sending email for certain errors such as network speed related issue,
setup settings.json file to your application.

```json
{
  "errors": {
    "suppressedErrors": [
      {
        "subject": "Connection timeout. No sockjs heartbeat received.",
        "reason": "Usually it occurs when user's network status is unstable for some reason"
      }
    ]
  }
}
```

Each error's ```subject``` is the error.details.message thrown by Meteor and ```reason``` is not actually related to the function, but it helps to track errors.

## Known Limitations

 - [ ] There is currently no UI for aggregating the errors.
 - [ ] There are currently no tests.
 - [ ] It only logs uncaught errors, but Meteor catches errors?

## License

MIT License (c) Lab80

Developed as part of the [Hello Money](http://hellomoney.co) project.
