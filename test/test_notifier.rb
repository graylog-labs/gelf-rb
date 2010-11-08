require 'helper'

HASH = {'short_message' => 'message', 'host' => 'localhost'}

class TestNotifier < Test::Unit::TestCase
  context "with notifier" do
    setup do
      @notifier = GELF::Notifier.new('host', 12345)
    end

    context "extract_hash" do
      should "check number of arguments" do
        assert_raise(ArgumentError) { @notifier.__send__(:extract_hash) }
        assert_raise(ArgumentError) { @notifier.__send__(:extract_hash, 1, 2, 3) }
      end

      should "work with plain-text" do
        Socket.stubs(:gethostname).returns("localhost")
        assert_equal HASH, @notifier.__send__(:extract_hash, 'message')
      end

      should "work with hash" do
        assert_equal HASH, @notifier.__send__(:extract_hash, HASH)
      end

      should "work with any object which responds to #to_hash" do
        o = Object.new
        o.expects(:to_hash).returns(HASH)
        assert_equal HASH, @notifier.__send__(:extract_hash, o)
      end

      should "work with exception with backtrace" do
        e = RuntimeError.new('message')
        e.set_backtrace(caller)
        hash = @notifier.__send__(:extract_hash, e)
        assert_equal 'RuntimeError: message', hash['short_message']
        assert_match /Backtrace/, hash['full_message']
      end

      should "work with exception without backtrace" do
        e = RuntimeError.new('message')
        hash = @notifier.__send__(:extract_hash, e)
        assert_match /Backtrace is not available/, hash['full_message']
      end

      should "work with exception and hash" do
        e, h = RuntimeError.new('message'), {'param' => 1, 'short_message' => 'will be hidden by exception'}
        hash = @notifier.__send__(:extract_hash, e, h)
        assert_equal 'RuntimeError: message', hash['short_message']
        assert_equal 1, hash['param']
      end
    end

    should "detect and cache host" do
      Socket.expects(:gethostname).once.returns("localhost")
      @notifier.expects(:do_notify).twice
      2.times { @notifier.notify('short_message' => 'message') }
    end

    context "datagrams" do
      should "not split short datagram" do
        UDPSocket.any_instance.expects(:send).once
        @notifier.notify(HASH)
      end

      should "split long datagram" do
        srand(1)
        UDPSocket.any_instance.expects(:send).twice
        @notifier.notify(HASH.merge('something' => (0..12000).map { rand(256).chr }.join))
      end
    end
  end
end
