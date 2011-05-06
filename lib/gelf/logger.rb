module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility
    # Does nothing.
    def close
    end

    # Use it like Logger#add... or better not to use at all.
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
  end

  # Graylog2 notifier, compatible with Ruby Logger.
  # You can use it with Rails like this:
  #     config.logger = GELF::Logger.new("localhost", 12201, "WAN", { :facility => "appname" })
  #     config.colorize_logging = false
  class Logger < Notifier
    include LoggerCompatibility
    @last_chunk_id = 0
  end
end
