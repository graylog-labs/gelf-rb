module GELF
  module Transport
    class UDP
      attr_reader :addresses

      def initialize(initial_addresses)
        self.addresses = initial_addresses
      end

      def addresses=(new_addresses)
        @addresses = new_addresses
        reset_sockets
      end
      
      def send_datagrams(datagrams)
        sock = socket
        datagrams.each do |datagram|
          sock.send(datagram, 0)
        end
      end

      def close
        reset_sockets
      end

      private

      def socket
        idx = socket_index
        sock = sockets[idx]
        set_socket_index((idx + 1) % @addresses.length)
        sock
      end

      def sockets
        Thread.current[:gelf_udp_sockets] ||= configure_sockets
      end

      def reset_sockets
        return unless Thread.current.key?(:gelf_udp_sockets)
        Thread.current[:gelf_udp_sockets].each(&:close)
        Thread.current[:gelf_udp_sockets] = nil
      end

      def socket_index
        Thread.current[:gelf_udp_socket_idx] ||= 0
      end

      def set_socket_index(value)
        Thread.current[:gelf_udp_socket_idx] = value
      end

      def configure_sockets
        @addresses.map do |host, port|
          UDPSocket.new(Addrinfo.ip(host).afamily).tap do |socket|
            socket.connect(host, port)
          end
        end
      end
    end
  end
end
