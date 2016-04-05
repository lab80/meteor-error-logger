Package.describe({
  summary: "Simple client-side error logging for Meteor",
  version: "0.0.1",
  name: "lab80:error-logger",
  git: "https://github.com/lab80/meteor-error-logger"
});

Npm.depends({
  "body-parser": "1.10.1"
});

Package.on_use(function (api, where) {
  api.versionsFrom('METEOR@0.9.2');

  api.use(['underscore', 'jquery', 'coffeescript', 'faisalman:ua-parser-js', 'http'], ['client']);
  api.addFiles('error_logger_client.coffee', 'client');
  api.export('ErrorLogger', 'client');

  api.use(['underscore', 'coffeescript', 'mongo', 'email', 'meteorhacks:picker', 'http'], ['server']);
  api.addFiles('error_logger_server.coffee', 'server');
  api.export('ErrorLogger', 'server');
});
