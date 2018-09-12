## GELF Ruby library

This is the new GELF gem written by Alexey Palazhchenko. It is based on the old gem by Lennart Koopmann and allows you to send GELF messages to Graylog or Logstash instances. See the [GELF specification](http://docs.graylog.org/en/stable/pages/gelf.html) for more information about GELF and [RDoc](http://rdoc.info/github/graylog-labs/gelf-rb/master/frames) for API documentation.

Tested with Ruby 1.9, 2.0, 2.1, 2.2, 2.3 and 2.4.

[![Build Status](https://travis-ci.org/graylog-labs/gelf-rb.svg?branch=master)](https://travis-ci.org/graylog-labs/gelf-rb)
[![Code Climate](https://codeclimate.com/github/graylog-labs/gelf-rb/badges/gpa.svg)](https://codeclimate.com/github/graylog-labs/gelf-rb)

## Usage
### Gelf::Notifier

This allows you to send arbitary messages via UDP to Graylog.

    n = GELF::Notifier.new("localhost", 12201)

    # Send with custom attributes and an additional parameter "foo"
    n.notify!(:short_message => "foo", :full_message => "something here\n\nbacktrace?!", :_foo => "bar")

    # Pass any object that responds to .to_hash
    n.notify!(Exception.new)

The recommended default is to send via UDP but you can choose to send via TCP like this:

    n = GELF::Notifier.new("127.0.0.1", 12201, "LAN", { :protocol => GELF::Protocol::TCP })

Note that the `LAN` or `WAN` option is ignored for TCP because no chunking happens. (Read below for more information.)

### Gelf::Logger

The Gelf::Logger is compatible with the standard Ruby Logger interface and can be used interchangeably.
Under the hood it uses Gelf::Notifier to send log messages via UDP to Graylog.

    logger = GELF::Logger.new("localhost", 12201, "WAN", { :facility => "appname" })

    logger.debug "foobar"
    logger.info "foobar"
    logger.warn "foobar"
    logger.error "foobar"
    logger.fatal "foobar"

    logger << "foobar"

Then `WAN` or `LAN` option influences the UDP chunk size depending on if you send in your own
network (LAN) or on a longer route (i.e. through the internet) and should be set accordingly.

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

Copyright (c) 2010-2016 Lennart Koopmann and Alexey Palazhchenko. See LICENSE for details.
