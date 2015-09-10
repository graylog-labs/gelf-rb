## GELF Ruby library

This is the new GELF gem written by Alexey Palazhchenko. It is based on the old gem by Lennart Koopmann and allows you to send GELF messages to Graylog2 server instances. See [http://www.graylog2.org/about/gelf](http://www.graylog2.org/about/gelf) for more information about GELF and [http://rdoc.info/github/Graylog2/gelf-rb/master/frames](http://rdoc.info/github/Graylog2/gelf-rb/master/frames) for API documentation.

Tested with Ruby 1.8.7, 1.9.x. and 2.0.x.

![](https://travis-ci.org/Graylog2/gelf-rb.png?branch=master)

## Usage
### Gelf::Notifier

This allows you to sent arbitary messages via UDP to your Graylog2 server.

  n = GELF::Notifier.new("localhost", 12201)

  # Send with custom attributes and an additional parameter "foo"
  n.notify!(:short_message => "foo", :full_message => "something here\n\nbacktrace?!", :_foo => "bar")

  # Pass any object that responds to .to_hash
  n.notify!(Exception.new)

### Gelf::Logger

The Gelf::Logger is compatible with the standard Ruby Logger interface and can be used interchangeably.
Under the hood it uses Gelf::Notifier to send log messages via UDP to Graylog2.

  logger = GELF::Logger.new("localhost", 12201, "WAN", { :facility => "appname" })
  
  logger.debug "foobar"
  logger.info "foobar"
  logger.warn "foobar"
  logger.error "foobar"
  logger.fatal "foobar"
  
  logger << "foobar"

Since it's compatible with the Logger interface, you can also use it in your Rails application:

  # config/environments/production.rb
  config.logger = GELF::Logger.new("localhost", 12201, "WAN", { :facility => "appname" })

### Note on Patches/Pull Requests

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010-2015 Lennart Koopmann and Alexey Palazhchenko. See LICENSE for details.
