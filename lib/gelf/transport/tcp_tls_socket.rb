require 'openssl'

module GELF
  module Transport
    # Provides encryption capabilities on the socket
    class TCPTLSSocket < TCPSocket
      # Supported options:
      # 'tls':
      #   'no_default_ca' [Boolean] prevents OpenSSL from using the systems CA store.
      #   'tls_version' [Symbol] any of :TLSv1, :TLSv1_1, :TLSv1_2 (default)
      #   'cert' [String, IO] the client certificate file
      #   'key' [String, IO] the key for the client certificate
      #   'all_ciphers' [Boolean] allows any ciphers to be used, may be insecure
      # 'keepalive' [Boolean] whether to enable TCP keepalive on the socket
      def initialize(host, port, options)
        options = {} if options.is_a?(TrueClass)
        @options = options
        super(host, port, options.delete('keepalive'))
      end

      # Overrides the socket accessor
      alias_method :plain_socket, :socket
      def socket
        @ssl_socket
      end

      def reconnect
        @ssl_socket = nil
        super
      end

      private

      def socket_connect
        @ssl_socket = nil if @ssl_socket && @ssl_socket.closed?
        return unless super
        @connected = start_tls
      rescue OpenSSL::OpenSSLError
        @ssl_socket.sysclose
        @ssl_socket = nil
        @socket = nil
        @connected = false
        raise # probably better than swallowing it
      end

      # Initiates TLS communication on the socket
      def start_tls
        @ssl_socket = OpenSSL::SSL::SSLSocket.new(@socket, ssl_context)
        @ssl_socket.sync_close = true
        @ssl_socket.connect # nonblock raises OpenSSL::SSL::SSLErrorWaitReadable -> ?!
        true
      end

      def ssl_context
        @ssl_context ||= OpenSSL::SSL::SSLContext.new.tap do |ctx|
          ctx.cert_store = ssl_cert_store
          ctx.ssl_version = tls_version
          ctx.verify_mode = verify_mode
          set_certificate_and_key(ctx)
          restrict_ciphers(ctx) unless tls_options['all_ciphers']
        end
      end

      def set_certificate_and_key(context)
        return unless tls_options['cert'] && tls_options['key']
        context.cert = OpenSSL::X509::Certificate.new(resource(tls_options['cert']))
        context.key = OpenSSL::PKey::RSA.new(resource(tls_options['key']))
      end

      # checks whether {resource} is a filename and tries to read it
      # otherwise treats it as if it already contains certificate/key data
      def resource(data)
        if data.is_a?(String) && File.exists?(data)
          File.read(data)
        else
          data
        end
      end

      def tls_options
        @tls_options ||= @options['tls'].is_a?(Hash) ? @options['tls'] : {}
      end

      # These are A-level ciphers as reported from Graylog 2.0.1 
      # which were also available on Ruby using OpenSSL 1.0.2h
      # A lot of AES-128-CBC based ciphers were not available
      SECURE_CIPHERS = %w(
                           AES128-GCM-SHA256
                           ECDHE-RSA-AES128-GCM-SHA256
                           DHE-RSA-AES128-GCM-SHA256
                         ).freeze
      def restrict_ciphers(ctx)
        ctx.ciphers = SECURE_CIPHERS
      end

      def verify_mode
        @options['no_verify'] ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
      end

      # SSL v2&3 are insecure, forces at least TLS v1.0 and defaults to v1.2
      def tls_version
        if tls_options.key?('version') &&
            OpenSSL::SSL::SSLContext::METHODS.include?(tls_options['version']) &&
            tls_options['version'] =~ /\ATLSv/
          tls_options['version']
        else
          :TLSv1_2
        end
      end

      def ssl_cert_store
        OpenSSL::X509::Store.new.tap do |store|
          # TODO: allow passing in expected server certificate and disabling system CAs
          store.set_default_paths
        end
      end
    end
  end
end
