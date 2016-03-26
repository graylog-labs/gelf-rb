module GELF
  module Transport
    class UDP
      attr_accessor :addresses

      def initialize(addresses)
        @addresses = addresses
      end

      def send_datagrams(datagrams)
        socket = get_socket
        idx = get_address_index

        host, port = @addresses[idx]
        set_address_index((idx + 1) % @addresses.length)
        datagrams.each do |datagram|
          socket.send(datagram, 0, host, port)
        end
      end

      def close
        socket = get_socket
        socket.close if socket
      end

      private

      def get_socket
        Thread.current[:gelf_udp_socket] ||= UDPSocket.open
      end

      def get_address_index
        Thread.current[:gelf_udp_address_idx] ||= 0
      end

      def set_address_index(value)
        Thread.current[:gelf_udp_address_idx] = value
      end
    end
  end
end
