module SyslogSD
  # Plain Ruby UDP sender.
  class RubyUdpSender
    attr_accessor :addresses

    def initialize(addresses)
      @addresses = addresses
      @i = 0
      @socket = UDPSocket.open
    end

    def send_datagram(datagram)
      host, port = @addresses[@i]
      @i = (@i + 1) % @addresses.length
      @socket.send(datagram, 0, host, port)
    end
  end
end
