module GELF
  class RubySender
    def initialize(host, port)
      @host, @port = host, port
      @socket = UDPSocket.open
    end

    def send_datagrams(datagrams)
      datagrams.each { |d| @socket.send(d, 0, @host, @port) }
    end
  end
end
