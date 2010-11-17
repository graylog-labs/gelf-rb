module GELF
  class Notifier
    @@id = 0

    attr_accessor :host, :port
    attr_reader :max_chunk_size, :default_options, :cache_size, :level #TODO docs for cache

    # +host+ and +port+ are host/ip and port of graylog2-server.
    # +max_size+ is passed to max_chunk_size=.
    # +default_options+ is used in notify!
    def initialize(host = 'localhost', port = 12201, max_size = 'WAN', default_options = {})
      self.level = GELF::DEBUG
      @cache = []
      self.cache_size = 1
      @default_options = {}

      @host, @port, self.max_chunk_size = host, port, max_size

      self.default_options = default_options
      self.default_options['host'] ||= Socket.gethostname
      self.default_options['level'] ||= GELF::DEBUG

      @sender = RubySender.new(host, port)
    end

    # +size+ may be a number of bytes, 'WAN' (1420 bytes) or 'LAN' (8154).
    # Default (safe) value is 'WAN'.
    def max_chunk_size=(size)
      s = size.to_s.downcase
      if s == 'wan'
        @max_chunk_size = 1420
      elsif s == 'lan'
        @max_chunk_size = 8154
      else
        @max_chunk_size = size.to_int
      end
    end

    def default_options=(options)
      @default_options = self.class.stringify_hash_keys(options)
    end

    def cache_size=(size)
      @cache_size = size
      send_pending_notifications if @cache.count > size
    end

    def level=(l)
      raise ArgumentError.new("Wrong level.") unless (0..5).include?(l)
      @level = l
    end

    # Same as notify!, but rescues all exceptions (including +ArgumentError+)
    # and sends them instead.
    def notify(*args, &block)
      notify!(*args, &block)
    rescue Exception => e
      notify!(e)
    end

    # Sends message to Graylog2 server.
    # +args+ can be:
    # - hash-like object (any object which responds to +to_hash+, including +Hash+ instance):
    #    notify!(:short_message => 'All your rebase are belong to us', :user => 'AlekSi')
    # - exception with optional hash-like object:
    #    notify!(SecurityError.new('ALARM!'), :trespasser => 'AlekSi')
    # - string-like object (anything which responds to +to_s+) with optional hash-like object:
    #    notify!('Plain olde text message', :scribe => 'AlekSi')
    # - lambda/proc or block, which generates anything from the above:
    #    notify! lambda{ 'This weird syntax is only' }
    #    notify!       { 'for compatibility with Ruby Logger' }
    # Resulted fields are merged with +default_options+, the latter will never overwrite the former.
    # This method will raise +ArgumentError+ if arguments are wrong. Consider using notify instead.
    def notify!(*args, &block)
      hash = extract_hash(*args, &block)
      if hash['level'] >= level
        @cache += datagrams_from_hash(hash)
        send_pending_notifications if @cache.count == cache_size
      end
    end

    # Sends all pending notifications.
    def send_pending_notifications
      if @cache.count > 0
        @sender.send_datagrams(@cache)
        @cache = []
      end
    end

    # TODO: docs
    GELF::LEVELS.each do |ruby_level_sym, syslog_level_num|
      define_method(ruby_level_sym) do |*args, &block|
        hash = extract_hash(*args, &block).merge('level' => syslog_level_num)
        notify(hash)
      end
    end

    # Calls +send_pending_notifications+ for compatibilty with Ruby Logger.
    def close
      send_pending_notifications
    end

  private
    def extract_hash(o = nil, args = {}, &block)
      primary_data = if block_given?
                       raise ArgumentError.new("Pass block without other parameters.") unless o.nil? && args == {}
                       yield
                     elsif o.is_a?(Proc)
                       raise ArgumentError.new("Pass lambda/proc without other parameters.") unless args == {}
                       o.call
                     elsif args.is_a?(Proc)
                       raise ArgumentError.new("Pass lambda/proc without other parameters.")
                     elsif o.respond_to?(:to_hash)
                       o.to_hash
                     elsif o.is_a?(Exception)
                       bt = o.backtrace || ["Backtrace is not available."]
                       { 'short_message' => "#{o.class}: #{o.message}", 'full_message' => "Backtrace:\n" + bt.join("\n") }
                     else
                       { 'short_message' => o.to_s }
                     end

      hash = self.class.stringify_hash_keys(args.merge(primary_data))
      hash = default_options.merge(hash)

      # for compatibility with HoptoadNotifier
      if hash['short_message'].to_s.empty?
        if hash.has_key?('error_class') && hash.has_key?('error_message')
          hash['short_message'] = "#{hash['error_class']}: #{hash['error_message']}"
          hash.delete('error_class')
          hash.delete('error_message')
        end
      end

      %w(short_message host).each do |a|
        if hash[a].to_s.empty?
          raise ArgumentError.new("Options short_message and host must be set.")
        end
      end

      hash
    end

    def datagrams_from_hash(hash)
      raise ArgumentError.new("Parameter is empty.") if hash.nil? || hash.empty?

      data = Zlib::Deflate.deflate(hash.to_json).bytes
      datagrams = []

      # Maximum total size is 8192 byte for UDP datagram. Split to chunks if bigger. (GELFv2 supports chunking)
      if data.count > @max_chunk_size
        @@id += 1
        msg_id = Digest::SHA256.digest("#{Time.now.to_f}-#{@@id}")
        i, count = 0, (data.count / 1.0 / @max_chunk_size).ceil
        data.each_slice(@max_chunk_size) do |slice|
          datagrams << chunk_data(slice, msg_id, i, count)
          i += 1
        end
      else
        datagrams = [data.map(&:chr).join]
      end

      datagrams
    end

    def chunk_data(data, msg_id, sequence_number, sequence_count)
      # [30, 15].pack('CC') => "\036\017"
      return "\036\017" + msg_id + [sequence_number, sequence_count].pack('nn') + data.map(&:chr).join
    end

    def self.stringify_hash_keys(hash)
      hash.keys.each do |key|
        value, key_s = hash.delete(key), key.to_s
        raise ArgumentError.new("Both #{key.inspect} and #{key_s} are present.") if hash.has_key?(key_s)
        hash[key_s] = value
      end
      hash
    end
  end
end
