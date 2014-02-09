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

  class RubyTcpSocket
    attr_reader :socket

    def initialize(host, port)
      @host = host
      @port = port
      connect
    end

    def connect
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      sockaddr = Socket.sockaddr_in(@port, @host)
      begin
        socket.connect_nonblock(sockaddr)
      rescue Errno::EINPROGRESS, Errno::EISCONN
      rescue Errno::EINVAL
        return false
      end
      @socket = socket
      return true
    end

    def matches?(host, port)
      if @host == host and @port == port
        true
      else
        false
      end
    end
  end

  class RubyTcpSender
    attr_reader :addresses

    def initialize(addresses)
      @sockets = []
      addresses.each do |address|
        s = RubyTcpSocket.new(address[0], address[1])
        @sockets.push(s)
      end
    end

    def addresses=(addresses)
      addresses.each do |address|
        found = false
        # handle pre existing sockets
        @sockets.each do |socket|
          if socket.matches?(address[0], address[1])
            found = true
            break
          end
        end
        if not found
          s = RubyTcpSocket.new(address[0], address[1])
          @sockets.push(s)
        end
      end
    end

    def send(message)
      while true do
        sent = false
        # need to only add sockets which are connected
        sockets = @sockets.map { |s| s.socket }
        begin
          result = select( nil, sockets, nil, 5)
          if result
            writers = result[1]
            sent = write_any(writers, message)
          end
          break if sent
        rescue SystemCallError, IOError
        end
      end
    end

    private
    def write_any(writers, message)
      writers.shuffle.each do |w|
        curr_handle = w
        begin
          curr_handle.write(message)
          return true
        rescue Errno::EPIPE
          @sockets.each do |s|
            if s.socket == curr_handle
              s.connect
            end
          end
        end
      end
      return false
    end
  end
end
