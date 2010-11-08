require 'helper'

class TestMessage < Test::Unit::TestCase
  context "with empty message" do
    setup do
      @message = GELF::Message.new
    end

    [:short_message, :full_message, :level, :host, :line, :file].each do |a|
      should "has methods for attribute #{a}" do
        @message.__send__("#{a}=", 'value')
        assert_equal 'value', @message.__send__(a)
      end
    end

    should "not has methods for additional attributes" do
      assert_raise(NoMethodError) { @message.some_attribute }
    end

    should "set and get additional attributes" do
      @message['key'] = 'value'
      assert_equal 'value', @message['key']
    end

    context "hash" do
      should "return hash with specified attributes" do
        @message.short_message = 'message'
        assert_equal({'short_message' => 'message'}, @message.to_hash)
      end

      should "not make a difference between symbols and strings for keys" do
        @message['a'] = 'bad'
        @message[:a]  = 'good'
        assert_equal 'good', @message[:a]
        assert_equal 'good', @message['a']
      end
    end
  end
end
