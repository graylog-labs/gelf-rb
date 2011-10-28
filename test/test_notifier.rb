require 'helper'

RANDOM_DATA = ('A'..'Z').to_a

class TestNotifier < Test::Unit::TestCase
  should "allow access to host, port, max_chunk_size and default_options" do
    Socket.expects(:gethostname).returns('default_hostname')
    n = GELF::Notifier.new
    assert_equal [[['localhost', 12201]], 1420], [n.addresses, n.max_chunk_size]
    assert_equal( { 'version' => '1.0', 'level' => GELF::UNKNOWN,
                    'host' => 'default_hostname', 'facility' => 'gelf-rb' },
                  n.default_options )
    n.addresses, n.max_chunk_size, n.default_options = [['graylog2.org', 7777]], :lan, {:host => 'grayhost'}
    assert_equal [['graylog2.org', 7777]], n.addresses
    assert_equal 8154, n.max_chunk_size
    assert_equal({'host' => 'grayhost'}, n.default_options)

    n.max_chunk_size = 1337.1
    assert_equal 1337, n.max_chunk_size
  end

  context "with notifier with mocked sender" do
    setup do
      Socket.stubs(:gethostname).returns('stubbed_hostname')
      @notifier = GELF::Notifier.new('host', 12345)
      @sender = mock
      @notifier.instance_variable_set('@sender', @sender)
    end

    context "extract_hash" do
      should "check arguments" do
        assert_raise(ArgumentError) { @notifier.__send__(:extract_hash) }
        assert_raise(ArgumentError) { @notifier.__send__(:extract_hash, 1, 2, 3) }
      end

      should "work with hash" do
        hash = @notifier.__send__(:extract_hash, { 'version' => '1.0', 'short_message' => 'message' })
        assert_equal '1.0', hash['version']
        assert_equal 'message', hash['short_message']
      end

      should "work with any object which responds to #to_hash" do
        o = Object.new
        o.expects(:to_hash).returns({ 'version' => '1.0', 'short_message' => 'message' })
        hash = @notifier.__send__(:extract_hash, o)
        assert_equal '1.0', hash['version']
        assert_equal 'message', hash['short_message']
      end

      should "work with exception with backtrace" do
        e = RuntimeError.new('message')
        e.set_backtrace(caller)
        hash = @notifier.__send__(:extract_hash, e)
        assert_equal 'RuntimeError: message', hash['short_message']
        assert_match /Backtrace/, hash['full_message']
        assert_equal GELF::ERROR, hash['level']
      end

      should "work with exception without backtrace" do
        e = RuntimeError.new('message')
        hash = @notifier.__send__(:extract_hash, e)
        assert_match /Backtrace is not available/, hash['full_message']
      end

      should "work with exception and hash" do
        e, h = RuntimeError.new('message'), {'param' => 1, 'level' => GELF::FATAL, 'short_message' => 'will be hidden by exception'}
        hash = @notifier.__send__(:extract_hash, e, h)
        assert_equal 'RuntimeError: message', hash['short_message']
        assert_equal GELF::FATAL, hash['level']
        assert_equal 1, hash['param']
      end

      should "work with plain text" do
        hash = @notifier.__send__(:extract_hash, 'message')
        assert_equal 'message', hash['short_message']
        assert_equal GELF::INFO, hash['level']
      end

      should "work with plain text and hash" do
        hash = @notifier.__send__(:extract_hash, 'message', 'level' => GELF::WARN)
        assert_equal 'message', hash['short_message']
        assert_equal GELF::WARN, hash['level']
      end

      should "covert hash keys to strings" do
        hash = @notifier.__send__(:extract_hash, :short_message => :message)
        assert hash.has_key?('short_message')
        assert !hash.has_key?(:short_message)
      end

      should "not overwrite keys on convert" do
        assert_raise(ArgumentError) { @notifier.__send__(:extract_hash, :short_message => :message1, 'short_message' => 'message2') }
      end

      should "use default_options" do
        @notifier.default_options = {:foo => 'bar', 'short_message' => 'will be hidden by explicit argument', 'host' => 'some_host'}
        hash = @notifier.__send__(:extract_hash, { 'version' => '1.0', 'short_message' => 'message' })
        assert_equal 'bar', hash['foo']
        assert_equal 'message', hash['short_message']
      end

      should "be compatible with HoptoadNotifier" do
        # https://github.com/thoughtbot/hoptoad_notifier/blob/master/README.rdoc, section Going beyond exceptions
        hash = @notifier.__send__(:extract_hash, :error_class => 'Class', :error_message => 'Message')
        assert_equal 'Class: Message', hash['short_message']
      end

      should "set file and line" do
        line = __LINE__
        hash = @notifier.__send__(:extract_hash, { 'version' => '1.0', 'short_message' => 'message' })
        assert_match /test_notifier.rb/, hash['file']
        assert_equal line + 1, hash['line']
      end

      should "set timestamp to current time if not set" do
        hash = @notifier.__send__(:extract_hash, { 'version' => '1.0', 'short_message' => 'message' })
        assert_instance_of Float, hash['timestamp']
        now = Time.now.utc.to_f
        assert ((now - 1)..(now + 1)).include?(hash['timestamp'])
      end

      should "set timestamp to specified time" do
        timestamp = 1319799449.13765
        hash = @notifier.__send__(:extract_hash, { 'version' => '1.0', 'short_message' => 'message', 'timestamp' => timestamp })
        assert_equal timestamp, hash['timestamp']
      end
    end

    context "serialize_hash" do
      setup do
        @notifier.level_mapping = :direct
        @notifier.instance_variable_set('@hash', { 'level' => GELF::WARN, 'field' => 'value' })
        @data = @notifier.__send__(:serialize_hash)
        assert @data.respond_to?(:each)  # Enumerable::Enumerator in 1.8, ::Enumerator in 1.9, so...
        @deserialized_hash = JSON.parse(Zlib::Inflate.inflate(@data.to_a.pack('C*')))
        assert_instance_of Hash, @deserialized_hash
      end

      should "map level using mapping" do
        assert_not_equal GELF::WARN, @deserialized_hash['level']
        assert_not_equal GELF::LOGGER_MAPPING[GELF::WARN], @deserialized_hash['level']
        assert_equal GELF::DIRECT_MAPPING[GELF::WARN], @deserialized_hash['level']
      end
    end

    context "datagrams_from_hash" do
      should "not split short data" do
        @notifier.instance_variable_set('@hash', { 'version' => '1.0', 'short_message' => 'message' })
        datagrams = @notifier.__send__(:datagrams_from_hash)
        assert_equal 1, datagrams.count
        assert_instance_of String, datagrams[0]
        assert_equal "\x78\x9c", datagrams[0][0..1] # zlib header
      end

      should "split long data" do
        srand(1) # for stable tests
        hash = { 'version' => '1.0', 'short_message' => 'message' }
        hash.merge!('something' => (0..3000).map { RANDOM_DATA[rand(RANDOM_DATA.count)] }.join) # or it will be compressed too good
        @notifier.instance_variable_set('@hash', hash)
        datagrams = @notifier.__send__(:datagrams_from_hash)
        assert_equal 2, datagrams.count
        datagrams.each_index do |i|
          datagram = datagrams[i]
          assert_instance_of String, datagram
          assert datagram[0..1] == "\x1e\x0f" # chunked GELF magic number
          # datagram[2..9] is a message id
          assert_equal i, datagram[10].ord
          assert_equal datagrams.count, datagram[11].ord
        end
      end
    end

    context "level threshold" do
      setup do
        @notifier.level = GELF::WARN
        @hash = { 'version' => '1.0', 'short_message' => 'message' }
      end

      ['debug', 'DEBUG', :debug].each do |l|
        should "allow to set threshold as #{l.inspect}" do
          @notifier.level = l
          assert_equal GELF::DEBUG, @notifier.level
        end
      end

      should "not send notifications with level below threshold" do
        @sender.expects(:send_datagrams).never
        @notifier.notify!(@hash.merge('level' => GELF::DEBUG))
      end

      should "not notifications with level equal or above threshold" do
        @sender.expects(:send_datagrams).once
        @notifier.notify!(@hash.merge('level' => GELF::WARN))
      end
    end

    context "when disabled" do
      setup do
        @notifier.disable
      end

      should "not send datagrams" do
        @sender.expects(:send_datagrams).never
        @notifier.expects(:extract_hash).never
        @notifier.notify!({ 'version' => '1.0', 'short_message' => 'message' })
      end

      context "and enabled again" do
        setup do
          @notifier.enable
        end

        should "send datagrams" do
          @sender.expects(:send_datagrams)
          @notifier.notify!({ 'version' => '1.0', 'short_message' => 'message' })
        end
      end
    end

    should "pass valid data to sender" do
      @sender.expects(:send_datagrams).with do |datagrams|
        datagrams.is_a?(Array) && datagrams[0].is_a?(String)
      end
      @notifier.notify!({ 'version' => '1.0', 'short_message' => 'message' })
    end

    GELF::Levels.constants.each do |const|
      should "call notify with level #{const} from method name" do
        @notifier.expects(:notify_with_level).with(GELF.const_get(const), { 'version' => '1.0', 'short_message' => 'message' })
        @notifier.__send__(const.downcase, { 'version' => '1.0', 'short_message' => 'message' })
      end
    end

    should "not rescue from invalid invocation of #notify!" do
      assert_raise(ArgumentError) { @notifier.notify!(:no_short_message => 'too bad') }
    end

    should "rescue from invalid invocation of #notify" do
      @notifier.expects(:notify_with_level!).with(nil, instance_of(Hash)).raises(ArgumentError)
      @notifier.expects(:notify_with_level!).with(GELF::UNKNOWN, instance_of(ArgumentError))
      assert_nothing_raised { @notifier.notify(:no_short_message => 'too bad') }
    end
  end

  context "with notifier with real sender" do
    setup do
      @notifier = GELF::Notifier.new('no_such_host_321')
    end

    should "raise exception" do
      assert_raise(SocketError) { @notifier.notify('Hello!') }
    end

    should "not raise exception if asked" do
      @notifier.rescue_network_errors = true
      assert_nothing_raised { @notifier.notify('Hello!') }
    end
  end
end
