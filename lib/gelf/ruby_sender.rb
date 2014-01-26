module GELF
  # Plain Ruby UDP sender.
  class RubyUdpSender
    attr_accessor :addresses

    def initialize(addresses)
      @addresses = addresses
      @i = 0
      @socket = UDPSocket.open
    end

    def send_datagrams(datagrams)
      host, port = @addresses[@i]
      @i = (@i + 1) % @addresses.length
      datagrams.each do |datagram|
        @socket.send(datagram, 0, host, port)
      end
    end
  end

  class RubyTcpSender
    attr_accessor :addresses

    def initialize(addresses)
      @addresses = addresses
      @i = 0
      @sockets = []
      @addresses.each do |address|
        @sockets.push(TCPSocket.open(address[0], address[1]))
      end
    end

    def send(message)
      # reconnect if necessary
      begin
        @sockets[@i].write(message)
      rescue Errno::ECONNRESET, Errno::EPIPE
        # reconnect and retry once but throw exceptions on failure
        address = addresses[@i]
        @sockets[@i] = TCPSocket.open(address[0], address[1])
        @sockets[@i].write(message)
      ensure
        @i = (@i + 1) % @addresses.length
      end
    end
  end
end
