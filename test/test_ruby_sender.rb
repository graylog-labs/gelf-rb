require 'helper'

class TestRubyUdpSender < Test::Unit::TestCase
  context "with ruby sender" do
    setup do
      @addresses = [['localhost', 12201], ['localhost', 12202]]
      @sender = GELF::Transport::UDP.new(@addresses)
      @datagrams1 = %w(d1 d2 d3)
      @datagrams2 = %w(e1 e2 e3)
    end

    context "setup_sockets" do
      setup do
        @sender.send_datagrams(%w(a1))
        @sender.send_datagrams(%w(b1))
      end

      before_should "be configured with a socket for each address" do
        UDPSocket.any_instance.expects(:connect).with do |host,port|
          host == 'localhost' && port == 12201
        end
        UDPSocket.any_instance.expects(:connect).with do |host,port|
          host == 'localhost' && port == 12202
        end
        UDPSocket.any_instance.expects(:send).times(2).returns(nil)
      end
    end

    context "send_datagrams" do
      setup do
        @sender.send_datagrams(@datagrams1)
        @sender.send_datagrams(@datagrams2)
      end

      before_should "be called 3 times with 1st and 2nd address" do
        UDPSocket.any_instance.expects(:send).times(3).with do |datagram,_|
          datagram.start_with?('d')
        end
        UDPSocket.any_instance.expects(:send).times(3).with do |datagram,_|
          datagram.start_with?('e')
        end
      end
    end
  end
end
