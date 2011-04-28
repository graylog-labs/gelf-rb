require 'helper'

class TestLogger < Test::Unit::TestCase
  context "with logger with mocked sender" do
    setup do
      Socket.stubs(:gethostname).returns('stubbed_hostname')
      @logger = GELF::Logger.new
      @sender = mock
      @logger.instance_variable_set('@sender', @sender)
    end

    should "respond to #close" do
      assert @logger.respond_to?(:close)
    end

    context "#add" do
      # logger.add(Logger::INFO, 'Message')
      should "implement add method with level and message from parameters, facility from defaults" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'gelf-rb'
        end
        @logger.add(GELF::INFO, 'Message')
      end

      # logger.add(Logger::INFO, RuntimeError.new('Boom!'))
      should "implement add method with level and exception from parameters, facility from defaults" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'] == 'gelf-rb'
        end
        @logger.add(GELF::INFO, RuntimeError.new('Boom!'))
      end

      # logger.add(Logger::INFO) { 'Message' }
      should "implement add method with level from parameter, message from block, facility from defaults" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'gelf-rb'
        end
        @logger.add(GELF::INFO) { 'Message' }
      end

      # logger.add(Logger::INFO) { RuntimeError.new('Boom!') }
      should "implement add method with level from parameter, exception from block, facility from defaults" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'] == 'gelf-rb'
        end
        @logger.add(GELF::INFO) { RuntimeError.new('Boom!') }
      end

      # logger.add(Logger::INFO, 'Message', 'Facility')
      should "implement add method with level, message and facility from parameters" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, 'Message', 'Facility')
      end

      # logger.add(Logger::INFO, RuntimeError.new('Boom!'), 'Facility')
      should "implement add method with level, exception and facility from parameters" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, RuntimeError.new('Boom!'), 'Facility')
      end

      # logger.add(Logger::INFO, 'Facility') { 'Message' }
      should "implement add method with level and facility from parameters, message from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, 'Facility') { 'Message' }
      end

      # logger.add(Logger::INFO, 'Facility') { RuntimeError.new('Boom!') }
      should "implement add method with level and facility from parameters, exception from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, 'Facility') { RuntimeError.new('Boom!') }
      end
    end

    GELF::Levels.constants.each do |const|
      # logger.error "Argument #{ @foo } mismatch."
      should "call add with level #{const} from method name, message from parameter" do
        @logger.expects(:add).with(GELF.const_get(const), 'message')
        @logger.__send__(const.downcase, 'message')
      end

      # logger.fatal { "Argument 'foo' not given." }
      should "call add with level #{const} from method name, message from block" do
        @logger.expects(:add).with(GELF.const_get(const), 'message')
        @logger.__send__(const.downcase) { 'message' }
      end

      # logger.info('initialize') { "Initializing..." }
      should "call add with level #{const} from method name, facility from parameter, message from block" do
        @logger.expects(:add).with(GELF.const_get(const), 'message', 'facility')
        @logger.__send__(const.downcase, 'facility') { 'message' }
      end

      should "respond to #{const.downcase}?" do
        @logger.level = GELF.const_get(const) - 1
        assert @logger.__send__(const.to_s.downcase + '?')
        @logger.level = GELF.const_get(const)
        assert @logger.__send__(const.to_s.downcase + '?')
        @logger.level = GELF.const_get(const) + 1
        assert !@logger.__send__(const.to_s.downcase + '?')
      end
    end

    should "support Logger#<<" do
      @logger.expects(:notify_with_level!).with do |level, hash|
        level == GELF::UNKNOWN &&
        hash['short_message'] == "Message"
      end
      @logger << "Message"
    end
  end
end
