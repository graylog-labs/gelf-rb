module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility

    attr_accessor :formatter, :log_tags

    # Use it like Logger#add... or better not to use at all.
    def add(level, message = nil, progname = nil, &block)
      progname ||= default_options['facility']

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = default_options['facility']
        end
      end

      message_hash = { 'facility' => progname }

      if message.is_a?(Hash)
        # Stringify keys.
        message.each do |k,v|
          message_hash[k.to_s] = message[k]
        end
      else
        message_hash['short_message'] = message
      end

      if message.is_a?(Exception)
        message_hash.merge!(self.class.extract_hash_from_exception(message))
      end

      # Include tags in message hash
      Array(log_tags).each_with_index do |tag_name, index|
        message_hash.merge!("_#{tag_name}" => current_tags[index]) if current_tags[index]
      end

      notify_with_level(level, message_hash)
    end

    # Redefines methods in +Notifier+.
    GELF::Levels.constants.each do |const|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{const.downcase}(progname = nil, &block)   # def debug(progname = nil, &block)
          add(GELF::#{const}, nil, progname, &block)    #   add(GELF::DEBUG, nil, progname, &block)
        end                                             # end

        def #{const.downcase}?                          # def debug?
          GELF::#{const} >= level                       #   GELF::DEBUG >= level
        end                                             # end
      EOT
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
      Thread.current[:gelf_tagged_logging_tags] ||= []
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
