require 'helper'

class TestSeverity < Test::Unit::TestCase
  should "map Ruby Logger levels to syslog levels" do
    GELF::LEVELS_MAPPING.each do |ruby_level, syslog_level|
      assert_not_equal syslog_level, ruby_level
    end
  end

  should "map Rails Logger levels to graylog levels" do
    assert_equal 7, GELF::RAILS_LEVELS_MAPPING[GELF::DEBUG]
    assert_equal 6, GELF::RAILS_LEVELS_MAPPING[GELF::INFO]
    assert_equal 4, GELF::RAILS_LEVELS_MAPPING[GELF::WARN]
    assert_equal 3, GELF::RAILS_LEVELS_MAPPING[GELF::ERROR]
    assert_equal 2, GELF::RAILS_LEVELS_MAPPING[GELF::FATAL]
    assert_equal 1, GELF::RAILS_LEVELS_MAPPING[GELF::UNKNOWN]
  end
end
