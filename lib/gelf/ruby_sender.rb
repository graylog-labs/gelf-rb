module GELF
  # Module definition for TCP
  module Protocol
    UDP = 0
    TCP = 1
  end

  # Plain Ruby UDP sender.
  class RubyUdpSender
    attr_accessor :addresses

    def initialize(addresses)
      @addresses = addresses
      @i = 0
      @socket = UDPSocket.open
    end

    def send_datagrams(datagrams)
      host, port = @addresses[@i]
      @i = (@i + 1) % @addresses.length
      datagrams.each do |datagram|
        @socket.send(datagram, 0, host, port)
      end
    end

    def close
      @socket.close
    end
  end

  # TCP/TLS socket management
  class RubyTcpSocket
    attr_accessor :socket

    require "socket"
    require "openssl"
    require "timeout"

    def initialize(host, port)
      @host = host
      @port = port
      @options = Notifier.options
      connect
    end

    def connected?
      if not @connected
        if defined? @options['tls'] and @options['tls'] != true
          begin
            if @socket.nil?
              @socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
            end
            sockaddr = Socket.sockaddr_in(@port, @host)
            @socket.connect_nonblock(sockaddr)
          rescue Errno::EISCONN
            @connected = true
          rescue Errno::EINPROGRESS, Errno::EALREADY
            @connected = false
          rescue SystemCallError
            @socket = nil
            @connected = false
          end
        else
          begin
            if @tcp.nil?
              @tcp = Socket.new(
                Socket::Constants::AF_INET,
                Socket::Constants::SOCK_STREAM,
                Socket::Constants::IPPROTO_IP
              )
              @tcp = TCPSocket.new @host, @port
            end
            if @socket.nil?
              tls_context = OpenSSL::SSL::SSLContext.new
              unless @options['check_ssl'].nil?
                if @options['check_ssl'] == true
                  tls_context.set_params({ :verify_mode=>OpenSSL::SSL::VERIFY_PEER})
                else
                  tls_context.set_params({ :verify_mode=>OpenSSL::SSL::VERIFY_NONE})
                end
              end
              unless @options['tls_version'].nil?
                if OpenSSL::SSL::SSLContext::METHODS.any? { |v| v.to_s.include?(@options['tls_version']) }
                  tls_context.set_params({ :ssl_version => @options['tls_version']})
                end
              end
              @socket = OpenSSL::SSL::SSLSocket.new(@tcp,tls_context)
              @socket.sync_close = true
              @socket.connect
            end
            @connected = true
          rescue Errno::EISCONN
            @connected = true
          rescue Errno::EINPROGRESS, Errno::EALREADY
            @connected = false
          rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ETIMEDOUT
            @socket = nil
            @connected = false
          rescue OpenSSL::SSL::SSLError
            @socket = nil
            @connected = false
          rescue SystemCallError
            @socket = nil
            @connected = false
          end
        end
      end
      return @connected
    end

    def connect
      @connected = false
      if defined? @options['tls'] and @options['tls'] != true
        socket = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
        sockaddr = Socket.sockaddr_in(@port, @host)
        begin
          socket.connect(sockaddr)
        rescue Errno::EISCONN
          @connected = true
        rescue SystemCallError
          return false
        end
      else
        begin
          tcp = Socket.new(
            Socket::Constants::AF_INET,
            Socket::Constants::SOCK_STREAM,
            Socket::Constants::IPPROTO_IP
          )
          tls_context = OpenSSL::SSL::SSLContext.new
          unless @options['check_ssl'].nil?
            if @options['check_ssl'] == true
              tls_context.set_params({ :verify_mode=>OpenSSL::SSL::VERIFY_PEER})
            else
              tls_context.set_params({ :verify_mode=>OpenSSL::SSL::VERIFY_NONE})
            end
          end
          unless @options['tls_version'].nil?
            if OpenSSL::SSL::SSLContext::METHODS.any? { |v| v.to_s.include?(@options['tls_version']) }
              tls_context.set_params({ :ssl_version => @options['tls_version']})
            end
          end
          tcp = TCPSocket.new(@host, @port)
          socket = OpenSSL::SSL::SSLSocket.new(tcp,tls_context)
          socket.sync_close = true
          socket.connect
        rescue Errno::EISCONN
          @connected = true
        rescue Errno::EINPROGRESS, Errno::EWOULDBLOCK
          return false
        rescue Errno::EHOSTUNREACH, Errno::ENETUNREACH, Errno::ECONNABORTED, Errno::ECONNREFUSED, Errno::ETIMEDOUT
          return false
        rescue OpenSSL::SSL::SSLError
          return false
        rescue SystemCallError
          return false
        end
        @tcp = tcp
      end
      @socket = socket
      return true
    end

    def matches?(host, port)
      if @host == host and @port == port
        true
      else
        false
      end
    end

    def close
      @socket.close unless @socket.nil?
      @socket = nil
      if !@options['tls'].nil? && @options['tls'] == true
        @tcp = nil
      end
    end
  end

  # Plain Ruby TCP sender.
  class RubyTcpSender
    attr_reader :addresses

    def initialize(addresses)
      @sockets = []
      addresses.each do |address|
        s = RubyTcpSocket.new(address[0], address[1])
        @sockets.push(s)
      end
      @options = Notifier.options
    end

    def addresses=(addresses)
      found = false
      # handle pre existing sockets
      @sockets.each do |socket|
        if socket.matches?(address[0], address[1])
          found = true
          break
        end
        if not found
          s = RubyTcpSocket.new(address[0], address[1])
          @sockets.push(s)
        end
      end
    end

    def send(message)
      if @options['tcp_retry'] and @options['tcp_retry'] =~ /^\d+$/?true:false
        max_retry = @options['tcp_retry'].to_i
      else
        max_retry = 0
      end
      if @options['tcp_retry_ms'] and @options['tcp_retry_ms'] =~ /^\d+$/?true:false
        sleep_retry = @options['tcp_retry_ms'].to_f
      else
        sleep_retry = 50
      end
      i = 0
      while i < max_retry || max_retry == 0 do
        sent = false
        timeout = 1
        sockets = @sockets.map { |s|
          if s.connected?
            s.socket
          else
            reconnect
          end
        }
        if max_retry != 0
          if i != 0
            sleep(sleep_retry/1000)
          end
          i += 1
        end
        next if sockets.compact.empty?
        begin
          result = select(sockets, sockets, nil, timeout)
        rescue SystemCallError, IOError, EOFError, OpenSSL::SSL::SSLError, TypeError, Errno::EPIPE
          reconnect
        end
        if result
          writers = result[1]
          sent = write_any(writers, message)
          readers = result[0]
          read = readable(readers)
        end
        return if sent && read
      end
      warn 'Maximum TCP connection retry reached'
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
              s.socket.close unless s.socket.nil?
              s.socket = nil
              @conencted=false
              s.connect
            end
          end
          return false
        end
      end
      return false
    end

    def readable(readers)
      readers.shuffle.each do |r|
        begin
          r.sysread(10)
        rescue EOFError, IOError
          @sockets.each do |s|
            if s.socket == r
              s.socket.close unless s.socket.nil?
              s.socket = nil
              @conencted=false
              s.connect
            end
          end
          return false
        end
      end
      return true
    end

    def reconnect
      @sockets.each do |s|
        s.socket.close unless s.socket.nil?
        s.socket = nil
        @conencted=false
        s.connect
      end
    end
  end

end
