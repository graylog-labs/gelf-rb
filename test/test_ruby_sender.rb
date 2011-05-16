require 'helper'

class TestRubyUdpSender < Test::Unit::TestCase
  context "with ruby sender" do
    setup do
      @addresses = [['localhost', 12201], ['localhost', 12202]]
      @sender = SyslogSD::RubyUdpSender.new(@addresses)
    end

    context "send_datagram" do
      setup do
        @sender.send_datagram("d1")
        @sender.send_datagram("e1")
        @sender.send_datagram("d2")
        @sender.send_datagram("e2")
      end

      before_should "be called 2 times with 1st and 2nd address" do
        UDPSocket.any_instance.expects(:send).times(2).with do |datagram, _, host, port|
          datagram.start_with?('d') && host == 'localhost' && port == 12201
        end
        UDPSocket.any_instance.expects(:send).times(2).with do |datagram, _, host, port|
          datagram.start_with?('e') && host == 'localhost' && port == 12202
        end
      end
    end
  end
end
