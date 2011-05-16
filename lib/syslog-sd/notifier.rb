module SyslogSD
  # syslog notifier.
  class Notifier
    attr_accessor :host, :port, :enabled
    attr_reader :level, :default_options, :level_mapping

    # +host+ and +port+ are host/ip and port of syslog server.
    # +default_options+ is used in notify!
    def initialize(host = 'localhost', port = 514, default_options = {})
      @enabled = true

      self.level = SyslogSD::DEBUG

      self.host, self.port = host, port

      self.default_options = default_options
      self.default_options['host'] ||= Socket.gethostname
      self.default_options['level'] ||= SyslogSD::UNKNOWN
      self.default_options['facility'] ||= 'syslog-sd-rb'
      self.default_options['procid'] ||= Process.pid

      @sender = RubyUdpSender.new([[host, port]])
      self.level_mapping = :logger
    end

    # proxy addresses getter to sender
    def addresses
      @sender.addresses
    end

    # proxy addresses setter to sender
    def addresses=(addrs)
      @sender.addresses = addrs
    end

    def level=(new_level)
      @level = if new_level.is_a?(Fixnum)
                 new_level
               else
                 SyslogSD.const_get(new_level.to_s.upcase)
               end
    end

    def default_options=(options)
      @default_options = self.class.stringify_keys(options)
    end

    # +mapping+ may be a hash, 'logger' (SyslogSD::LOGGER_MAPPING) or 'direct' (SyslogSD::DIRECT_MAPPING).
    # Default (compatible) value is 'logger'.
    def level_mapping=(mapping)
      case mapping.to_s.downcase
        when 'logger'
          @level_mapping = SyslogSD::LOGGER_MAPPING
        when 'direct'
          @level_mapping = SyslogSD::DIRECT_MAPPING
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

    SyslogSD::Levels.constants.each do |const|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{const.downcase}(*args)                          # def debug(*args)
          notify_with_level(SyslogSD::#{const}, *args)        #   notify_with_level(SyslogSD::DEBUG, *args)
        end                                                   # end
      EOT
    end

  private
    def notify_with_level(message_level, *args)
      notify_with_level!(message_level, *args)
    rescue Exception => exception
      notify_with_level!(SyslogSD::UNKNOWN, exception)
    end

    def notify_with_level!(message_level, *args)
      return unless @enabled
      extract_hash(*args)
      @hash['level'] = message_level unless message_level.nil?
      if @hash['level'] >= level
        @sender.send_datagram(serialize_hash)
      end
    end

    def extract_hash(object = nil, args = {})
      primary_data = if object.respond_to?(:to_hash)
                       object.to_hash
                     elsif object.is_a?(Exception)
                       args['level'] ||= SyslogSD::ERROR
                       self.class.extract_hash_from_exception(object)
                     else
                       args['level'] ||= SyslogSD::INFO
                       { 'short_message' => object.to_s }
                     end

      @hash = default_options.merge(self.class.stringify_keys(args.merge(primary_data)))
      convert_hoptoad_keys_to_graylog2
      set_file_and_line
      check_presence_of_mandatory_attributes
      @hash
    end

    def self.extract_hash_from_exception(exception)
      bt = exception.backtrace || ["Backtrace is not available."]
      { 'short_message' => "#{exception.class}: #{exception.message}", 'full_message' => "Backtrace:\n" + bt.join("\n") }
    end

    # Converts Hoptoad-specific keys in +@hash+ to Graylog2-specific.
    def convert_hoptoad_keys_to_graylog2
      if @hash['short_message'].to_s.empty?
        if @hash.has_key?('error_class') && @hash.has_key?('error_message')
          @hash['short_message'] = @hash.delete('error_class') + ': ' + @hash.delete('error_message')
        end
      end
    end

    CALLER_REGEXP = /^(.*):(\d+).*/
    LIB_PATTERN = File.join('lib', 'syslog-sd')

    def set_file_and_line
      stack = caller
      begin
        frame = stack.shift
      end while frame.include?(LIB_PATTERN)
      match = CALLER_REGEXP.match(frame)
      @hash['file'] = match[1]
      @hash['line'] = match[2].to_i
    end

    def check_presence_of_mandatory_attributes
      %w(short_message host).each do |attribute|
        if @hash[attribute].to_s.empty?
          raise ArgumentError.new("#{attribute} is missing. Options short_message and host must be set.")
        end
      end
    end

    def serialize_hash
      raise ArgumentError.new("Hash is empty.") if @hash.nil? || @hash.empty?

      @hash['level'] = @level_mapping[@hash['level']]

      prival = 128 + @hash['level'] # 128 = 16(local0) * 8
      t = Time.now.utc
      timestamp = t.strftime("%Y-%m-%dT%H:%M:%S.#{t.usec.to_s[0,3]}Z")
      msgid = @hash['msgid'] || '-'
      sd = '-'
      "<#{prival}>1 #{timestamp} #{@hash['host']} #{@hash['facility']} #{@hash['procid']} #{msgid} " +
        "#{sd} #{@hash['short_message']}"
    end

    def self.stringify_keys(hash)
      hash.keys.each do |key|
        value, key_s = hash.delete(key), key.to_s
        raise ArgumentError.new("Both #{key.inspect} and #{key_s} are present.") if hash.has_key?(key_s)
        hash[key_s] = value
      end
      hash
    end
  end
end
