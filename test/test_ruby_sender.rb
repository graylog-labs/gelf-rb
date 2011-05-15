require 'helper'

class TestRubyUdpSender < Test::Unit::TestCase
  context "with ruby sender" do
    setup do
      @host, @port = 'localhost', 12201
      @sender = SyslogSD::RubyUdpSender.new('localhost', 12201)
      @datagram = "datagram"
    end

    context "send_datagrams" do
      setup do
        @sender.send_datagram(@datagram)
      end

      before_should "be called" do
        UDPSocket.any_instance.expects(:send).with(@datagram, 0, @host, @port)
      end
    end
  end
end
