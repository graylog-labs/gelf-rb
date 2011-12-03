require 'thread'

module GELF
  # Plain Ruby UDP sender.
  class RubyUdpSender
    def initialize(addrs)
      @mutex = ::Mutex.new
      @socket = UDPSocket.open
      self.addresses = addrs
    end

    def addresses
      @addresses
    end

    def addresses=(addrs)
      @mutex.synchronize do
        @addresses = addrs
        @i = 0
        @addresses_length = addrs.length
      end
    end

    def send_datagrams(datagrams)
      # not thread-safe, but we don't care if round-robin algo fails sometimes
      host, port = @addresses[@i]
      @i = (@i + 1) % @addresses_length

      datagrams.each do |datagram|
        @socket.send(datagram, 0, host, port)
      end
    end
  end
end
