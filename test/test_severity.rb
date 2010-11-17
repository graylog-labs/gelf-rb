require 'helper'

class TestSeverity < Test::Unit::TestCase
  should "map Ruby Logger levels to syslog levels" do
    GELF::LEVELS_MAPPING.each do |ruby_level, syslog_level|
      unless ruby_level == GELF::ERROR
        assert_not_equal syslog_level, ruby_level
      else
        assert_equal syslog_level, ruby_level
      end
    end
  end
end
