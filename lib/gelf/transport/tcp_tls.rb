require 'openssl'

module GELF
  module Transport
    # Provides encryption capabilities for TCP connections
    class TCPTLS < TCP
      # Supported tls_options:
      #   'no_default_ca' [Boolean] prevents OpenSSL from using the systems CA store.
      #   'version' [Symbol] any of :TLSv1, :TLSv1_1, :TLSv1_2 (default)
      #   'ca' [String] the path to a custom CA store
      #   'cert' [String, IO] the client certificate file
      #   'key' [String, IO] the key for the client certificate
      #   'all_ciphers' [Boolean] allows any ciphers to be used, may be insecure
      #   'rescue_ssl_errors' [Boolean] similar to rescue_network_errors in notifier.rb, allows SSL exceptions to be raised
      #   'no_verify' [Boolean] disable peer verification

      attr_accessor :rescue_ssl_errors

      def initialize(addresses, tls_options={})
        @tls_options = tls_options
        @rescue_ssl_errors = @tls_options['rescue_ssl_errors']
        @rescue_ssl_errors if @rescue_ssl_errors.nil?
        super(addresses)
      end

      protected

      def write_socket(socket, message)
        super(socket, message)
      rescue OpenSSL::SSL::SSLError
        socket.close unless socket.closed?
        raise unless rescue_ssl_errors
        false
      end

      def connect(host, port)
        plain_socket = super(host, port)
        start_tls(plain_socket)
      rescue OpenSSL::SSL::SSLError
        plain_socket.close unless plain_socket.closed?
        raise unless rescue_ssl_errors
        nil
      end

      # Initiates TLS communication on the socket
      def start_tls(plain_socket)
        ssl_socket_class.new(plain_socket, ssl_context).tap do |ssl_socket|
          ssl_socket.sync_close = true
          ssl_socket.connect
        end
      end

      def ssl_socket_class
        if defined?(Celluloid::IO::SSLSocket)
          Celluloid::IO::SSLSocket
        else
          OpenSSL::SSL::SSLSocket
        end
      end

      def ssl_context
        @ssl_context ||= OpenSSL::SSL::SSLContext.new.tap do |ctx|
          ctx.cert_store = ssl_cert_store
          ctx.ssl_version = tls_version
          ctx.verify_mode = verify_mode
          set_certificate_and_key(ctx)
          restrict_ciphers(ctx) unless @tls_options['all_ciphers']
        end
      end

      def set_certificate_and_key(context)
        return unless @tls_options['cert'] && @tls_options['key']
        context.cert = OpenSSL::X509::Certificate.new(resource(@tls_options['cert']))
        context.key = OpenSSL::PKey::RSA.new(resource(@tls_options['key']))
      end

      # checks whether {resource} is a filename and tries to read it
      # otherwise treats it as if it already contains certificate/key data
      def resource(data)
        if data.is_a?(String) && File.exist?(data)
          File.read(data)
        else
          data
        end
      end

      # Ciphers have to come from the CipherString class, specifically the _TXT_ constants here - https://github.com/jruby/jruby-openssl/blob/master/src/main/java/org/jruby/ext/openssl/CipherStrings.java#L47-L178
      def restrict_ciphers(ctx)
        # This CipherString is will allow a variety of 'currently' cryptographically secure ciphers, 
        # while also retaining a broad level of compatibility
        ctx.ciphers = "TLSv1_2:TLSv1_1:TLSv1:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!ECDSA:!ADH:!IDEA:!3DES"
      end

      def verify_mode
        @tls_options['no_verify'] ? OpenSSL::SSL::VERIFY_NONE : OpenSSL::SSL::VERIFY_PEER
      end

      # SSL v2&3 are insecure, forces at least TLS v1.0 and defaults to v1.2
      def tls_version
        if @tls_options.key?('version') &&
            OpenSSL::SSL::SSLContext::METHODS.include?(@tls_options['version']) &&
            @tls_options['version'] =~ /\ATLSv/
          @tls_options['version']
        else
          :TLSv1_2
        end
      end

      def ssl_cert_store
        OpenSSL::X509::Store.new.tap do |store|
          unless @tls_options['no_default_ca']
            store.set_default_paths
          end

          if @tls_options.key?('ca')
            ca = @tls_options['ca']
            if File.directory?(ca)
              store.add_path(@tls_options['ca'])
            elsif File.file?(ca)
              store.add_file(ca)
            else
              $stderr.puts "No directory or file: #{ca}"
            end
          end
        end
      end
    end
  end
end
