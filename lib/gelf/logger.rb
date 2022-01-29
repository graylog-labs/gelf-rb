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
      new_keys, new_values = push_tags(*tags)
      yield self
    ensure
      log_tags.pop(new_keys.size)
      current_tags.pop(new_values.size)
    end

    # be aware direct call of #push_tags will overwrite defined log_tags - current_tags values
    # if log_tags is defined globally better use #tagged
    def push_tags(*tags)
      new_keys, new_values = to_new_keys_and_values(*tags)
      self.log_tags = Array(log_tags).concat(new_keys)
      current_tags.concat(new_values)

      return new_keys, new_values
    end

    def to_new_keys_and_values(*tags)
      new_tags = tags.flatten
      values_to_fill = (log_tags && log_tags.size - current_tags.size) || 0
      new_values = []
      new_keys = []

      if tags.first.is_a?(Hash)
        new_tags.first.reject! { |k, v| k.respond_to?(:empty?) ? !!k.empty? : !k || v.respond_to?(:empty?) ? !!v.empty? : !v }
        new_keys = new_tags.first.keys
        new_values = Array.new(values_to_fill, '').concat(new_tags.first.values)

        return new_keys, new_values
      end

      if values_to_fill > 0
        new_values = new_tags.shift(values_to_fill)
      end

      unless new_tags.empty?
        new_tags.reject{ |t| t.respond_to?(:empty?) ? !!t.empty? : !t }.each.with_index(1) do |tag, index|
          new_keys << "tag_#{(log_tags&.size || 0) + index}"
          new_values << tag
        end
      end

      return new_keys, new_values
    end

    def current_tags
      val = Thread.current.thread_variable_get(:gelf_tagged_logging_tags)
      return val unless val.nil?
      Thread.current.thread_variable_set(:gelf_tagged_logging_tags, [])
    end

    def clear_tags!
      self.log_tags.clear
      current_tags.clear
    end

    def pop_tags(size = 1)
      log_tags.pop(size)
      current_tags.pop(size)
    end

    def pop_tag_by_key(key)
      index = log_tags.index { |log_tag_key| log_tag_key.to_s == key.to_s }
      log_tags.delete_at(index)
      current_tags.delete_at(index)
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
  #
  # To add constants log_tags values - be aware it will overwrite config.log_tags:
  #   logger.push_tags({environment: 'production', stage: 'production'})
  # To add additional log_tags in block:
  #   logger.tagged({tag_name: 'tag_value'}) { logger.info('...') }


  class Logger < Notifier
    include LoggerCompatibility
  end

end
