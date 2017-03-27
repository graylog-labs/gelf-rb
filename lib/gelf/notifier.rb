require 'gelf/transport/udp'
require 'gelf/transport/tcp'
require 'gelf/transport/tcp_tls'

module GELF
  # Graylog2 notifier.
  class Notifier
    # Maximum number of GELF chunks as per GELF spec
    MAX_CHUNKS = 128
    MAX_CHUNK_SIZE_WAN = 1420
    MAX_CHUNK_SIZE_LAN = 8154

    attr_accessor :enabled, :collect_file_and_line, :rescue_network_errors
    attr_reader :max_chunk_size, :level, :default_options, :level_mapping

    # +host+ and +port+ are host/ip and port of graylog2-server.
    # +max_size+ is passed to max_chunk_size=.
    # +default_options+ is used in notify!
    def initialize(host = 'localhost', port = 12201, max_size = 'WAN', default_options = {})
      @enabled = true
      @collect_file_and_line = true
      @random = Random.new

      self.level = GELF::DEBUG
      self.max_chunk_size = max_size
      self.rescue_network_errors = false

      self.default_options = default_options.dup
      self.default_options['version'] = SPEC_VERSION
      self.default_options['host'] ||= Socket.gethostname
      self.default_options['level'] ||= GELF::UNKNOWN
      self.default_options['facility'] ||= 'gelf-rb'
      self.default_options['protocol'] ||= GELF::Protocol::UDP

      self.level_mapping = :logger
      @sender = create_sender(host, port)
    end

    # Get a list of receivers.
    #    notifier.addresses  # => [['localhost', 12201], ['localhost', 12202]]
    def addresses
      @sender.addresses
    end

    # Set a list of receivers.
    #    notifier.addresses = [['localhost', 12201], ['localhost', 12202]]
    def addresses=(addrs)
      @sender.addresses = addrs
    end

    # +size+ may be a number of bytes, 'WAN' (1420 bytes) or 'LAN' (8154).
    # Default (safe) value is 'WAN'.
    def max_chunk_size=(size)
      case size.to_s.downcase
        when 'wan'
          @max_chunk_size = MAX_CHUNK_SIZE_WAN
        when 'lan'
          @max_chunk_size = MAX_CHUNK_SIZE_LAN
        else
          @max_chunk_size = size.to_int
      end
    end

    def level=(new_level)
      @level = if new_level.is_a?(Integer)
                 new_level
               else
                 GELF.const_get(new_level.to_s.upcase)
               end
    end

    def default_options=(options)
      @default_options = self.class.stringify_keys(options)
    end

    # +mapping+ may be a hash, 'logger' (GELF::LOGGER_MAPPING) or 'direct' (GELF::DIRECT_MAPPING).
    # Default (compatible) value is 'logger'.
    def level_mapping=(mapping)
      case mapping.to_s.downcase
        when 'logger'
          @level_mapping = GELF::LOGGER_MAPPING
        when 'direct'
          @level_mapping = GELF::DIRECT_MAPPING
        else
          @level_mapping = mapping
      end
    end

    def disable
      @enabled = false
    end

    def enable
      @enabled = true
    end

    # Closes sender
    def close
      @sender.close
    end

    # Same as notify!, but rescues all exceptions (including +ArgumentError+)
    # and sends them instead.
    def notify(*args)
      notify_with_level(nil, *args)
    end

    # Sends message to Graylog2 server.
    # +args+ can be:
    # - hash-like object (any object which responds to +to_hash+, including +Hash+ instance):
    #    notify!(:short_message => 'All your rebase are belong to us', :user => 'AlekSi')
    # - exception with optional hash-like object:
    #    notify!(SecurityError.new('ALARM!'), :trespasser => 'AlekSi')
    # - string-like object (anything which responds to +to_s+) with optional hash-like object:
    #    notify!('Plain olde text message', :scribe => 'AlekSi')
    # Resulted fields are merged with +default_options+, the latter will never overwrite the former.
    # This method will raise +ArgumentError+ if arguments are wrong. Consider using notify instead.
    def notify!(*args)
      notify_with_level!(nil, *args)
    end

    GELF::Levels.constants.each do |const|
      define_method(const.downcase) do |*args|
        level = GELF.const_get(const)
        notify_with_level(level, *args)
      end
    end

  private

    def create_sender(host, port)
      addresses = [[host, port]]
      if default_options['protocol'] == GELF::Protocol::TCP
        if default_options.key?('tls')
          tls_options = default_options.delete('tls')
          GELF::Transport::TCPTLS.new(addresses, tls_options)
        else
          GELF::Transport::TCP.new(addresses)
        end
      else
        GELF::Transport::UDP.new(addresses)
      end
    end

    def notify_with_level(message_level, *args)
      notify_with_level!(message_level, *args)
    rescue SocketError, SystemCallError
      raise unless rescue_network_errors
    rescue Exception => exception
      notify_with_level!(GELF::UNKNOWN, exception)
    end

    def notify_with_level!(message_level, *args)
      return unless @enabled
      hash = extract_hash(*args)
      hash['level'] = message_level unless message_level.nil?
      if hash['level'] >= level
        if default_options['protocol'] == GELF::Protocol::TCP
          validate_hash(hash)
          @sender.send(hash.to_json + "\0")
        else
          @sender.send_datagrams(datagrams_from_hash(hash))
        end
      end
    end

    def extract_hash(object = nil, args = {})
      primary_data = if object.respond_to?(:to_hash)
                       object.to_hash
                     elsif object.is_a?(Exception)
                       args['level'] ||= GELF::ERROR
                       self.class.extract_hash_from_exception(object)
                     else
                       args['level'] ||= GELF::INFO
                       { 'short_message' => object.to_s }
                     end

      hash = default_options.merge(self.class.stringify_keys(args.merge(primary_data)))
      convert_hoptoad_keys_to_graylog2(hash)
      set_file_and_line(hash) if @collect_file_and_line
      set_timestamp(hash)
      check_presence_of_mandatory_attributes(hash)
      hash
    end

    def self.extract_hash_from_exception(exception)
      bt = exception.backtrace || ["Backtrace is not available."]
      {
        'short_message' => "#{exception.class}: #{exception.message}",
        'full_message' => "Backtrace:\n" + bt.join("\n")
      }
    end

    # Converts Hoptoad-specific keys in +@hash+ to Graylog2-specific.
    def convert_hoptoad_keys_to_graylog2(hash)
      if hash['short_message'].to_s.empty?
        if hash.has_key?('error_class') && hash.has_key?('error_message')
          hash['short_message'] = hash.delete('error_class') + ': ' + hash.delete('error_message')
        end
      end
    end

    CALLER_REGEXP = /^(.*):(\d+).*/
    LIB_GELF_PATTERN = File.join('lib', 'gelf')

    def set_file_and_line(hash)
      stack = caller
      frame = stack.find { |f| !f.include?(LIB_GELF_PATTERN) }
      match = CALLER_REGEXP.match(frame)
      hash['file'] = match[1]
      hash['line'] = match[2].to_i
    end

    def set_timestamp(hash)
      hash['timestamp'] = Time.now.utc.to_f if hash['timestamp'].nil?
    end

    def check_presence_of_mandatory_attributes(hash)
      %w(version short_message host).each do |attribute|
        if hash[attribute].to_s.empty?
          raise ArgumentError.new("#{attribute} is missing. Options version, short_message and host must be set.")
        end
      end
    end

    def datagrams_from_hash(hash)
      data = serialize_hash(hash)
      datagrams = []

      # Maximum total size is 8192 byte for UDP datagram. Split to chunks if bigger. (GELF v1.0 supports chunking)
      if data.count > @max_chunk_size
        id = @random.bytes(8)
        msg_id = Digest::MD5.digest("#{Time.now.to_f}-#{id}")[0, 8]
        num, count = 0, (data.count.to_f / @max_chunk_size).ceil
        if count > MAX_CHUNKS
          raise ArgumentError, "Data too big (#{data.count} bytes), would create more than #{MAX_CHUNKS} chunks!"
        end
        data.each_slice(@max_chunk_size) do |slice|
          datagrams << "\x1e\x0f" + msg_id + [num, count, *slice].pack('C*')
          num += 1
        end
      else
        datagrams << data.to_a.pack('C*')
      end

      datagrams
    end

    def validate_hash(hash)
      raise ArgumentError.new("Hash is empty.") if hash.nil? || hash.empty?
      hash['level'] = @level_mapping[hash['level']]
    end

    def serialize_hash(hash)
      validate_hash(hash)

      Zlib::Deflate.deflate(hash.to_json).bytes
    end

    def self.stringify_keys(hash)
      hash.keys.each do |key|
        value, key_s = hash.delete(key), key.to_s
        raise ArgumentError.new("Both #{key.inspect} and #{key_s} are present.") if hash.key?(key_s)
        value = stringify_keys(value) if value.is_a?(Hash)
        hash[key_s] = value
      end
      hash
    end
  end
end
