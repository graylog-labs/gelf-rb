require 'gelf/transport/tcp_socket'

module GELF
  module Transport
    class TCP
      attr_reader :addresses

      def initialize(addresses)
        @sockets = []
        @addresses = addresses.each { |a| create_socket(*a) }
      end

      def addresses=(addresses)
        @addresses = addresses.each do |address|
          # handle pre-existing sockets
          next if @sockets.any? { |s| s.matches?(*address) }
          create_socket(*address)
        end
      end

      def send(message)
        loop do
          sockets = @sockets.find_all(&:connected?).map(&:socket)
          next if sockets.empty?
          begin
            result = IO.select(nil, sockets, nil, 1)
            next if result.nil?
            writers = result[1]
            break if write_any(writers, message)
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
            @sockets.find_all { |s| s.socket == w }.each(&:reconnect)
          end
        end
        false
      end

      def create_socket(host, port)
        s = GELF::Transport::TCPSocket.new(host, port)
        @sockets.push(s)
      end
    end
  end
end
