module GELF
  # Methods for compatibility with Ruby Logger.
  module LoggerCompatibility
    # Calls send_pending_notifications
    def close
      send_pending_notifications
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

      hash = {'short_message' => message, 'level' => level, 'facility' => facility}
      hash.merge!(extract_hash_from_exception(message)) if message.is_a?(Exception)
      notify(hash)
    end

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
  end
end