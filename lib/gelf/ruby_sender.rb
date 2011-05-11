module GELF
  # Plain Ruby UDP sender.
  class RubyUdpSender
    def initialize(host, port)
      @host, @port = host, port
      @socket = UDPSocket.open
    end

    def send_datagrams(datagrams)
      datagrams.each do |datagram|
        @socket.send(datagram, 0, @host, @port)
      end
    end
  end
end
