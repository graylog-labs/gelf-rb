module GELF
  module Transport
    class TCP
      attr_reader :addresses

      # `addresses` Array of [host, port] pairs
      def initialize(addresses)
        @sockets = []
        self.addresses = addresses
      end

      def addresses=(addresses)
        @addresses = addresses.dup.freeze.tap do |addrs|
          @sockets.each(&:close)
          @sockets = addrs.map { |peer| connect(*peer) }
        end
      end

      def send(message)
        return if @addresses.empty?
        loop do
          connected = @sockets.reject(&:closed?)
          reconnect_all if connected.empty?
          break if write_any(connected, message)
        end
      end

      private

      def connect(host, port)
        socket_class.new(host, port)
      end

      def reconnect_all
        @sockets = @sockets.each_with_index.map do |old_socket, index|
          old_socket.closed? ? connect(*@addresses[index]) : old_socket
        end
      end

      def socket_class
        if defined?(Celluloid::IO::TCPSocket)
          Celluloid::IO::TCPSocket
        else
          ::TCPSocket
        end
      end

      def write_any(sockets, message)
        sockets.shuffle.each do |socket|
          return true if write_socket(socket, message)
        end
        false
      end

      def write_socket(socket, message)
        unsafe_write_socket(socket, message)
      rescue IOError, SystemCallError
        socket.close unless socket.closed?
        false
      end

      def unsafe_write_socket(socket, message)
        r,w = IO.select([socket], [socket])
        # Read everything first
        while r.any? do
          # don't expect any reads, but a readable socket might
          # mean the remote end closed, so read it and throw it away.
          # we'll get an EOFError if it happens.
          socket.sysread(16384)
          r = IO.select([socket])
        end

        # Now send the payload
        return false unless w.any?
        return socket.syswrite(message) > 0
      end
    end
  end
end
