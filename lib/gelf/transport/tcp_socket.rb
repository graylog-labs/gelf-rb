module GELF
  module Transport
    class TCPSocket
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
  end
end
