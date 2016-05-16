module GELF
  module Transport
    class TCPSocket
      attr_reader :socket

      def initialize(host, port, keepalive=false)
        @host = host
        @port = port
        @socket = nil
        @keepalive = keepalive
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
        if @socket.nil?
          @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
          setup_keepalive if @keepalive
        end

        @socket.connect_nonblock(@sockaddr)
        @connected = true
      rescue Errno::EISCONN
        @connected = true
      rescue Errno::EINPROGRESS, Errno::EALREADY
        @connected = false
      rescue SystemCallError
        @socket = nil
        @connected = false
      end

      def setup_keepalive
        @socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
        # It may be useful to set up more elaborate timeouts depending on the situation
        # @socket.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPIDLE, 50)
        # @socket.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPINTVL, 10)
        # @socket.setsockopt(Socket::SOL_TCP, Socket::TCP_KEEPCNT, 5)
      end
    end
  end
end
