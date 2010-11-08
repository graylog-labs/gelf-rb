module GELF
  class Message
    def initialize
      @attributes = {}
    end

    def [](key)
      @attributes[key.to_s]
    end

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

    def to_hash
      @attributes
    end
  end
end
