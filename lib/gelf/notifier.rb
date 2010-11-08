module GELF
  class Notifier
    MAX_CHUNK_SIZE = 8154

    @@id = 0

    attr_reader :host, :port

    # +host+ and +port+ are host/ip and port of graylog2-server.
    def initialize(host, port)
      @host, @port = host, port
    end

    # Sends message to Graylog2 server.
    # +args+ can be:
    # - any object which responds to +to_hash+
    # - exception
    # - exception with hash or object which responds to +to_hash+
    # - string or anything which responds to +to_s+
    def notify(*args)
      do_notify(extract_hash(args))
    end

  private
    def extract_hash(*args)
      raise ArgumentError.new("Please pass one or two arguments.") if args.count < 1 || args.count > 2

      arg = args.first
      hash = if args.count == 2
               args.last.merge(extract_hash_from_exception(args.first))
             elsif arg.respond_to?(:to_hash)
               arg.to_hash
             elsif arg.is_a?(Exception)
               extract_hash_from_exception(arg)
             else
               { 'short_message' => arg.to_s }
             end

      hash['host'] ||= @this_host || detect_this_host

      %w(short_message host).each do |a|
        if hash[a].to_s.empty?
          raise ArgumentError.new("Attributes short_message and host must be set. #{a} is not present or empty.")
        end
      end

      hash
    end

    def extract_hash_from_exception(e)
      bt = e.backtrace || ["Backtrace is not available."]
      { 'short_message' => "#{e.class}: #{e.message}", 'full_message' => "Backtrace:\n" + bt.join("\n") }
    end

    def do_notify(hash)
      data = Zlib::Deflate.deflate(hash.to_json).bytes
      sock = UDPSocket.open
      datagrams = []

      # Maximum total size is 8192 byte for UDP datagram. Split to chunks if bigger. (GELFv2 supports chunking)
      if data.count > MAX_CHUNK_SIZE
        @@id += 1
        msg_id, i, count = Digest::SHA256.digest("#{Time.now.to_f}-#{@@id}"), 0, (data.count / 1.0 / MAX_CHUNK_SIZE).ceil
        data.each_slice(MAX_CHUNK_SIZE) do |slice|
          datagrams << chunk_data(slice.to_a.join, msg_id, i, count)
          i += 1
        end
      else
        datagrams = [data.to_a.join]
      end

      datagrams.each { |d| sock.send(d, 0, @host, @port) }
    end

    def chunk_data(data, msg_id, sequence_number, sequence_count)
      # [30, 15].pack('CC') => "\036\017"
      return "\036\017" + msg_id + [sequence_number, sequence_count].pack('nn') + data
    end

    def detect_this_host
      @this_host = Socket.gethostname
    end
  end
end
