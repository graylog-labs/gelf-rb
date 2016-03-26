module GELF
  module Transport
    class TCPSocket
      attr_accessor :socket

      def initialize(host, port)
        @host = host
        @port = port
        @socket = nil
        @sockaddr = Socket.sockaddr_in(@port, @host)
        @connected = false
        connect
      end

      def connected?
        if not @connected
          begin
            if @socket.nil?
              @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
            end
            @socket.connect_nonblock(@sockaddr)
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
        @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        begin
          @socket.connect_nonblock(@sockaddr)
        rescue Errno::EISCONN
          @connected = true
        rescue Errno::EINPROGRESS, Errno::EALREADY
          @connected = false
        rescue SystemCallError
          @socket = nil
          return false
        end
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
