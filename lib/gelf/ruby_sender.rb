module GELF
  # Plain Ruby UDP sender.
  class RubyUdpSender
    def initialize(addrs)
      @mutex = ::Mutex.new
      @socket = UDPSocket.open
      @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDBUF, 65507)  # 65535 - 20 (ip header) - 8 (udp header)
      self.addresses = addrs
    end

    def addresses
      @mutex.synchronize do
        @i = 0
        @addresses
      end
    end

    def addresses=(addrs)
      @mutex.synchronize do
        @i = 0
        @addresses = addrs
      end
    end

    def send_datagrams(datagrams)
      # not thread-safe, but we don't care if round-robin algo fails sometimes
      host, port = @addresses[@i]
      @i = (@i + 1) % @addresses.length

      datagrams.each do |datagram|
        @socket.send(datagram, 0, host, port)
      end
    end
  end
end
