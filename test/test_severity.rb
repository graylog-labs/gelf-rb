require 'helper'

class TestSeverity < Test::Unit::TestCase
  should "map Ruby Logger levels to syslog levels as SyslogLogger" do
    GELF::LOGGER_MAPPING.each do |ruby_level, syslog_level|
      assert_not_equal syslog_level, ruby_level
    end
  end
end
