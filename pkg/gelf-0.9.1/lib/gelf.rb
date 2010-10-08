require 'rubygems'
require 'json'
require 'socket'
require 'zlib'
require 'digest/sha2'

class Gelf

  MAX_CHUNK_SIZE = 8154

  attr_accessor :short_message, :full_message, :level, :host, :type, :line, :file

  def initialize hostname, port
    @hostname = hostname
    @port = port
  end

  def send
    # Check if all required parameters are set.
    if self.short_message == nil or self.host == nil
      raise "Missing required information. Attributes short_message and host must be set."
    end

    data = {
      "short_message" => self.short_message,
      "full_message" => self.full_message,
      "level" => self.level,
      "host" => self.host,
      "type" => self.type,
      "line" => self.line,
      "file" => self.file
    }

    # Convert to JSON and deflate (ZLIB)
    data = Zlib::Deflate.deflate(data.to_json)
    
    # Create a socket to send the data.
    sock = UDPSocket.open
    
    # Maximum total size is 8192 byte for UDP datagram. Split to chunks if bigger. (GELFv2 supports chunking)
    if data.length > MAX_CHUNK_SIZE
      # Too big for one datagram. Send in chunks.

      # Build a message ID.
      msg_id = Time.now.to_f.to_s + rand(10000).to_s

      # Split data to chunks
      data_chunks = Array.new
      data.chars.each_slice(MAX_CHUNK_SIZE){|slice| data_chunks << slice.join}

      # Send every chunk
      i = 0
      data_chunks.each do |chunk|
        sock.send prepend_chunk_data(chunk, msg_id, i, data_chunks.size), 0, @hostname, @port
       i += 1
      end
    else
      # Data fits in datagram without chunking. Send!
      sock.send data, 0, @hostname, @port
    end
  end

  def prepend_chunk_data data, msg_id, sequence_number, sequence_count
    raise "Data must be a string and not be empty." if data == nil or data.length == 0
    raise "Message ID must be a string and not be empty." if msg_id == nil or msg_id.length == 0
    raise "Sequence count must be bigger than 0." if sequence_count <= 0
    raise "Sequence number must not be higher than sequence count." if sequence_number > sequence_count

    # Get raw binary (packed) GELF ID
    gelf_id_bin = [ 30, 15 ].pack('CC')

    # Get raw binary SHA256 hash of message ID
    digest = Digest::SHA256.new << msg_id
    msg_id_bin = digest.digest

    # Get raw binary (packed) sequence count and number
    sequence_nums_bin = [ sequence_number, sequence_count ].pack('nn');

    # Combine and prepend to message chunk
    return gelf_id_bin + msg_id_bin + sequence_nums_bin + data
  end

end
