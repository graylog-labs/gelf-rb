module GELF
  # GELF message. Additional methods: +short_message+, +full_message+, +level+, +host+, +line+, +file+.
  class Message
    def initialize(atrs = {})
      @attributes = {}
      atrs.each_pair { |key, value| self[key] = value }
    end

    # Get any attribute.
    def [](key)
      @attributes[key.to_s]
    end

    # Set any attribute.
    def []=(key, value)
      @attributes[key.to_s] = value
    end

    [:short_message, :full_message, :level, :host, :line, :file].each do |k|
      define_method(k) do
        self[k]
      end

      define_method("#{k}=") do |v|
        self[k] = v
      end
    end

    # Called by GELF::Notifier.
    def to_hash
      @attributes
    end
  end
end
