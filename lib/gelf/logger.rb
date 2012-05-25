module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility
    # Does nothing.
    def close
    end

    # Use it like Logger#add... or better not use directly at all.
    def add(level, *args)
      raise ArgumentError.new('Wrong arguments.') unless (0..2).include?(args.count)

      # Ruby Logger's author is a maniac.
      message, progname = if args.count == 2
                            [args[0], args[1]]
                          elsif args.count == 0
                            [yield, default_options['facility']]
                          elsif block_given?
                            [yield, args[0]]
                          else
                            [args[0], default_options['facility']]
                          end

      hash = {'short_message' => message, 'facility' => progname}
      hash.merge!(self.class.extract_hash_from_exception(message)) if message.is_a?(Exception)
      if default_options['tags']
        tags = current_tags
        default_options['tags'].each_with_index do |tag_name, index|
          hash.merge!("_#{tag_name}" => tags[index]) if tags[index]
        end
      end
      notify_with_level(level, hash)
    end

    # Redefines methods in +Notifier+.
    GELF::Levels.constants.each do |const|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{const.downcase}(*args)                  # def debug(*args)
          args.unshift(yield) if block_given?         #   args.unshift(yield) if block_given?
          add(GELF::#{const}, *args)                  #   add(GELF::DEBUG, *args)
        end                                           # end

        def #{const.downcase}?                        # def debug?
          GELF::#{const} >= level                     #   GELF::DEBUG >= level
        end                                           # end
      EOT
    end

    def <<(message)
      notify_with_level(GELF::UNKNOWN, 'short_message' => message)
    end

    def tagged(*new_tags)
      tags     = current_tags
      new_tags = new_tags.flatten.reject(&:blank?)
      tags.concat new_tags
      yield self
    ensure
      tags.pop(new_tags.size)
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
  #     config.log_tags = [:uuid, :remote_ip]
  #     config.colorize_logging = false
  #     config.logger = GELF::Logger.new("localhost", 12201, 'LAN', {
  #       tags: [:uuid_name, :remote_ip_name], # same order as config.log_tags
  #       facility: 'Jobmensa 2'
  #     })
  class Logger < Notifier
    include LoggerCompatibility
  end
end
