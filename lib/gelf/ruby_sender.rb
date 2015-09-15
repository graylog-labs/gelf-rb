module GELF
  # Plain Ruby UDP sender.
  class RubyUdpSender
    attr_accessor :addresses

    def initialize(addresses)
      self.addresses = addresses
      @i = 0
    end

    def send_datagrams(datagrams)
      # Choose next round robin socket to use to send all datagrams
      socket = sockets[@i]
      @i = (@i + 1) % @addresses.length

      datagrams.each do |datagram|
        socket.send(datagram, 0)
      end
    end

    def close
      @sockets.each(&:close) if @sockets
      @sockets = nil
    end

    # Set new addresses for the sender
    def addresses=(addresses)
      # Close any previously bound sockets
      close

      @addresses = addresses
    end

    private

    # Get UDPSockets that are prebound to the given addresses
    def sockets
      @sockets ||= addresses.map do |address|
        host, port = address

        socket = UDPSocket.new
        socket.connect(host, port)
        socket
      end
    end
  end
end
