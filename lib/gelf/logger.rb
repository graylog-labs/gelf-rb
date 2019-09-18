module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility

    attr_accessor :formatter, :log_tags

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

      return if !message_hash.key?('short_message') || message_hash['short_message'].empty?

      # Include tags in message hash
      Array(log_tags).each_with_index do |tag_name, index|
        message_hash.merge!("_#{tag_name}" => current_tags[index]) if current_tags[index]
      end

      notify_with_level(level, message_hash)
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

    def tagged(*tags)
      new_tags = push_tags(*tags)
      yield self
    ensure
      current_tags.pop(new_tags.size)
    end

    def push_tags(*tags)
      tags.flatten.reject{ |t| t.respond_to?(:empty?) ? !!t.empty? : !t }.tap do |new_tags|
        current_tags.concat new_tags
      end
    end

    def current_tags
      val = Thread.current.thread_variable_get(:gelf_tagged_logging_tags)
      return val unless val.nil?
      Thread.current.thread_variable_set(:gelf_tagged_logging_tags, [])
    end
  end

  # Graylog2 notifier, compatible with Ruby Logger.
  # You can use it with Rails like this:
  #     config.logger = GELF::Logger.new("localhost", 12201, "WAN", { :facility => "appname" })
  #     config.colorize_logging = false
  #
  # Tagged logging (with tags from rack middleware) (order of tags is important)
  # Adds custom gelf messages: { '_uuid_name' => <uuid>, '_remote_ip_name' => <remote_ip> }
  #     config.logger = GELF::Logger.new("localhost", 12201, "LAN", { :facility => "appname" })
  #     config.log_tags = [:uuid, :remote_ip]
  #     config.logger.log_tags = [:uuid_name, :remote_ip_name] # Same order as config.log_tags
  class Logger < Notifier
    include LoggerCompatibility
  end

end
