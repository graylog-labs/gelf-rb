module GELF
  class RubySender
    def initialize(host, port)
      @host, @port = host, port
    end

    def send_datagrams(datagrams)
      socket = UDPSocket.open
      datagrams.each { |d| socket.send(d, 0, @host, @port) }
    end
  end
end
