require 'gelf/transport/tcp_socket'

module GELF
  module Transport
    class TCP
      attr_reader :addresses

      def initialize(addresses)
        @sockets = []
        addresses.each do |address|
          s = GELF::Transport::TCPSocket.new(address[0], address[1])
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
            s = GELF::Transport::TCPSocket.new(address[0], address[1])
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
end
