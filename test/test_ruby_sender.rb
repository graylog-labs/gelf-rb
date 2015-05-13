require 'helper'

class TestRubyUdpSender < Test::Unit::TestCase
  context "with ruby sender" do
    setup do
      @addresses = [['localhost', 12201], ['localhost', 12202]]
      @sender = GELF::RubyUdpSender.new(@addresses)
      @datagrams1 = %w(d1 d2 d3)
      @datagrams2 = %w(e1 e2 e3)
    end

    context "send_datagrams" do
      before_should "be called 3 times with 1st and 2nd datagrams" do
        sockets = [mock, mock]

        @sender.instance_variable_set('@sockets', sockets)

        sockets[0].expects(:send).times(3).with do |datagram, _|
          datagram.start_with?('d')
        end
        sockets[1].expects(:send).times(3).with do |datagram, _|
          datagram.start_with?('e')
        end

        @sender.send_datagrams(@datagrams1)
        @sender.send_datagrams(@datagrams2)
      end

      should "set the proper hostname and ports" do
        sockets = @sender.send(:sockets)

        assert_equal ['localhost', '12201'], sockets[0].remote_address.getnameinfo
        assert_equal ['localhost', '12202'], sockets[1].remote_address.getnameinfo
      end
    end

    context "close" do
      should "close all open sockets" do
        sockets = @sender.send(:sockets)

        sockets[0].expects(:close)
        sockets[1].expects(:close)

        @sender.close
      end

      should "not fail if no sockets open" do
        @sender.close
      end

      should 'reset sockets' do
        original_sockets = @sender.send(:sockets)

        # Sanity check that sockets method returns same socket connections
        assert_equal original_sockets, @sender.send(:sockets)
        @sender.close

        # Check that sockets returns new sockets
        assert_not_equal original_sockets, @sender.send(:sockets)
      end
    end

    context "addresses=" do
      should "close old connections" do
        @sender.expects(:close)
        @sender.addresses = ['localhost', 12201]
      end

      should "set new addresses" do
        @sender.addresses = [['localhost', 12201]]
        assert_equal [['localhost', 12201]], @sender.addresses
      end
    end
  end
end
