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

    def close
      @socket.close
    end
  end

  class RubyTcpSocket
    attr_accessor :socket

    def initialize(host, port)
      @host = host
      @port = port
      connect
    end

    def connected?
      if not @connected
        begin
          if @socket.nil?
            @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
          end
          sockaddr = Socket.sockaddr_in(@port, @host)
          @socket.connect_nonblock(sockaddr)
        rescue Errno::EISCONN
          @connected = true
        rescue Errno::EINPROGRESS, Errno::EALREADY
          @connected = false
        rescue SystemCallError
          @socket = nil
          @connected = false
        end
      end
      return @connected
    end

    def connect
      @connected = false
      socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      sockaddr = Socket.sockaddr_in(@port, @host)
      begin
        socket.connect_nonblock(sockaddr)
      rescue Errno::EISCONN
        @connected = true
      rescue SystemCallError
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
        sockets = @sockets.map { |s|
          if s.connected?
            s.socket
          end
        }
        sockets.compact!
        next unless not sockets.empty?
        begin
          result = select( nil, sockets, nil, 1)
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
        begin
          w.write(message)
          return true
        rescue Errno::EPIPE
          @sockets.each do |s|
            if s.socket == w
              s.socket.close
              s.socket = nil
              s.connect
            end
          end
        end
      end
      return false
    end
  end
end
