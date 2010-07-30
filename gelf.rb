require 'rubygems'
require 'json'
require 'socket'
require 'zlib'

module Graylog2

  class Gelf

    GRAYLOG2_HOSTNAME = 'localhost'
    GRAYLOG2_PORT = 12201

    attr_accessor :short_message, :full_message, :level, :host, :type, :line, :file

    def send
      # Check if all required parameters are set.
      if self.short_message == nil or self.host == nil
        raise "Missing required information. Attributes short_message and host must be set."
      end

      data = {
        "short_message" => self.short_message,
        "full_message" => self.full_message,
        "level" => self.level,
        "host" => self.host,
        "type" => self.type,
        "line" => self.line,
        "file" => self.file
      }

      # Convert to JSON.
      data = data.to_json
      
      # Send
      sock = UDPSocket.open
      sock.send Zlib::Deflate.deflate(data, Zlib::BEST_COMPRESSION), 0, Graylog2::Gelf::GRAYLOG2_HOSTNAME, Graylog2::Gelf::GRAYLOG2_PORT
    end

  end

end
