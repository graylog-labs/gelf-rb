module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility
    # Does nothing.
    def close
    end

    # Use it like Logger#add… or better not to use at all.
    def add(level, *args)
      raise ArgumentError.new('Wrong arguments.') unless (0..2).include?(args.count)

      # Ruby Logger's author is a maniac.
      message, facility = if args.count == 2
                            [args[0], args[1]]
                          elsif args.count == 0
                            [yield, nil]
                          elsif block_given?
                            [yield, args[0]]
                          else
                            [args[0], nil]
                          end

      hash = {'short_message' => message}
      hash['facility'] = facility if facility
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
      notify('short_message' => message, 'level' => GELF::UNKNOWN)
    end
  end

  # Graylog2 notifier, compatible with Ruby Logger.
  class Logger < Notifier
    include LoggerCompatibility
    @last_chunk_id = 0
  end
  
  class RailsLogger < Notifier
    GELF::Levels.constants.each do |const|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{const.downcase}?                        # def debug?
          GELF::#{const} >= level                     #   GELF::DEBUG >= level
        end                                           # end
      EOT
    end
    
    def map_level(level)
      GELF::RAILS_LEVELS_MAPPING[level]
    end
  end
  
end
