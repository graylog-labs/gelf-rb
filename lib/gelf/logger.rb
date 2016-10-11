module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility

    attr_accessor :formatter

    # Use it like Logger#add... or better not to use at all.
    def add(level, message = nil, progname = nil, &block)
      progname ||= default_options['facility']
      message ||= block.call unless block.nil?

      if message.nil?
        message = progname
        progname = default_options['facility']
      end

      message_hash = { 'facility' => progname }

      if message.is_a?(Hash)
        message.each do |key, value|
          message_hash[key.to_s] = value.to_s
        end
      else
        message_hash['short_message'] = message.to_s
      end

      if message.is_a?(Exception)
        message_hash.merge!(self.class.extract_hash_from_exception(message))
      end

      if message_hash.key?('short_message') && !message_hash['short_message'].empty?
        notify_with_level(level, message_hash)
      end
    end

    # Redefines methods in +Notifier+.
    GELF::Levels.constants.each do |const|
      method_name = const.downcase

      define_method(method_name) do |progname=nil, &block|
        const_level = GELF.const_get(const)
        add(const_level, nil, progname, &block)
      end

      define_method("#{method_name}?") do
        const_level = GELF.const_get(const)
        const_level >= level
      end
    end

    def <<(message)
      notify_with_level(GELF::UNKNOWN, 'short_message' => message)
    end
  end

  # Graylog2 notifier, compatible with Ruby Logger.
  # You can use it with Rails like this:
  #     config.logger = GELF::Logger.new("localhost", 12201, "WAN", { :facility => "appname" })
  #     config.colorize_logging = false
  class Logger < Notifier
    include LoggerCompatibility
  end

end
