# For compatability with 0.9.3.
# This file is to be removed in 1.0.0 release.

class Gelf
  def deprecate(instead)
    Kernel.caller.first =~ /:in `(.+)'$/
    warn "Gelf##{$1} is deprecated. Use #{instead} instead."
  end

  attr_reader :notifier, :message

  def initialize(hostname, port)
    deprecate('GELF::Notifier.new(hostname, port) and GELF::Message.new')
    @notifier = GELF::Notifier.new(hostname, port)
    @message = GELF::Message.new
  end

  # bizarre, but Gelf did this...
  def send
    deprecate('GELF::Notifier#notify(message)')
    GELF::Notifier.notify
  end

  [:short_message, :full_message, :level, :host, :line, :file].each do |a|
    define_method a do
      deprecate("GELF::Message##{a}")
      @message.__send__(a)
    end

    define_method "#{a}=" do |value|
      deprecate("GELF::Message##{a} = value")
      @message.__send__("#{a}=", value)
    end
  end
end
