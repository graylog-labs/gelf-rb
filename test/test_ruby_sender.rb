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
      setup do
        @sender.send_datagrams(@datagrams1)
        @sender.send_datagrams(@datagrams2)
      end

      before_should "be called 3 times with 1st and 2nd address" do
        UDPSocket.any_instance.expects(:send).times(3).with do |datagram, _, host, port|
          datagram.start_with?('d') && host == 'localhost' && port == 12201
        end
        UDPSocket.any_instance.expects(:send).times(3).with do |datagram, _, host, port|
          datagram.start_with?('e') && host == 'localhost' && port == 12202
        end
      end
    end
  end
end
