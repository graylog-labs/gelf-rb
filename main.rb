require 'gelf.rb'

gelf = Graylog2::Gelf.new

gelf.short_message = "Short message"
gelf.full_message = "Stacktrace here"
gelf.level = 1
gelf.host = "localhost"
gelf.file = "somefile.rb"
gelf.line = 356

gelf.send
