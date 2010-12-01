# Deprecated, do not use in new code, to be removed.
class Gelf
  def deprecate(instead)
    Kernel.caller.first =~ /:in `(.+)'$/
    warn "Gelf##{$1} is deprecated. Use #{instead} instead."
  end

  attr_reader :notifier, :message

  def initialize(hostname, port)
    deprecate('GELF::Notifier.new(hostname, port)')
    @notifier = GELF::Notifier.new(hostname, port)
    @message = {}
  end

  # bizarre, but Gelf did this...
  def send
    deprecate('GELF::Notifier#notify(message)')
    @notifier.notify(@message)
  end

  [:short_message, :full_message, :level, :host, :line, :file].each do |attribute|
    define_method attribute do
      deprecate("GELF::Message##{attribute}")
      @message[attribute]
    end

    define_method "#{attribute}=" do |value|
      deprecate("GELF::Message##{attribute} = value")
      @message[attribute] = value
    end
  end

  def add_additional(key, value)
    @message[key] = value
  end
end
