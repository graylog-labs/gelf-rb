module GELF
  module Transport
    class UDP
      attr_accessor :addresses

      def initialize(addresses)
        @addresses = addresses
      end

      def send_datagrams(datagrams)
        socket = (Thread.current[:gelf_udp_socket] ||= UDPSocket.open)
        i = (Thread.current[:gelf_udp_address_idx] ||= 0)

        host, port = @addresses[i]
        Thread.current[:gelf_udp_address_idx] = (i + 1) % @addresses.length
        datagrams.each do |datagram|
          socket.send(datagram, 0, host, port)
        end
      end

      def close
        socket = Thread.current[:gelf_udp_socket]
        socket.close if socket
      end
    end
  end
end
