module GELF
  module Transport
    class TCPSocket
      attr_reader :socket

      def initialize(host, port)
        @host = host
        @port = port
        @socket = nil
        @sockaddr = Socket.sockaddr_in(@port, @host)
        @connected = false
        connect
      end

      def connected?
        socket_connect unless @connected
        @connected
      end

      def connect
        @connected = false
        socket_connect
      end

      def reconnect
        @socket.close unless @socket.nil?
        @socket = nil
        connect
      end

      def matches?(host, port)
        @host == host and @port == port
      end

      private

      def socket_connect
        begin
          if @socket.nil?
            @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
          end

          @socket.connect_nonblock(@sockaddr)
          @connected = true
        rescue Errno::EISCONN
          @connected = true
        rescue Errno::EINPROGRESS, Errno::EALREADY
          @connected = false
        rescue SystemCallError
          @connected = false
          @socket = nil
        end

        @connected
      end
    end
  end
end
