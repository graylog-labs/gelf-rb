# Deprecated, do not use in new code, to be removed.
class Gelf
  def deprecate(instead)
    Kernel.caller.first =~ /:in `(.+)'$/
    warn "Gelf##{$1} is deprecated. Use #{instead} instead."
  end

  attr_reader :notifier, :message

  def initialize(hostname, port)
    deprecate('GELF::Notifier.new(hostname, port) and GELF::Message.new')
    @notifier = GELF::Notifier.new(hostname, port)
    @message = {}
  end

  # bizarre, but Gelf did this...
  def send
    deprecate('GELF::Notifier#notify(message)')
    @notifier.notify(@message)
  end

  [:short_message, :full_message, :level, :host, :line, :file].each do |a|
    define_method a do
      deprecate("GELF::Message##{a}")
      @message[a]
    end

    define_method "#{a}=" do |value|
      deprecate("GELF::Message##{a} = value")
      @message[a] = value
    end
  end

  def add_additional(key, value)
    @message[key] = value
  end
end
