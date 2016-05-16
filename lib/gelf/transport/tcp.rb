require 'gelf/transport/tcp_socket'
require 'gelf/transport/tcp_tls_socket'

module GELF
  module Transport
    class TCP
      attr_reader :addresses

      # supported options:
      # keepalive [Boolean] whether to turn on TCP keepalive on the socket
      # tls [TrueClass, FalseClass, Hash] see {GELF::Transport::TCPTLSSocket} for a list of options
      def initialize(addresses, options={})
        @sockets = []
        @options = sanitize_options(options)
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

      def sanitize_options(options)
        case options['tls']
        when TrueClass then options['tls'] = {}
        when FalseClass then options.delete('tls')
        when Hash then # all is well
        else
          raise ArgumentError, "Unsupported TLS options type #{options['tls'].class}"
        end
        options
      end

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
        s = if @options['tls']
          GELF::Transport::TCPTLSSocket.new(host, port, @options)
        else
          GELF::Transport::TCPSocket.new(host, port, !!@options['keepalive'])
        end
        @sockets.push(s)
      end
    end
  end
end
