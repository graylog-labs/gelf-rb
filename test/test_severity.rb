require 'helper'

class TestSeverity < Test::Unit::TestCase
  should "map Ruby Logger levels to syslog levels" do
    GELF::LEVELS.each do |ruby_level_sym, syslog_level_num|
      unless ruby_level_sym == :error
        assert_not_equal syslog_level_num, GELF.const_get(ruby_level_sym.to_s.upcase)
      else
        assert_equal GELF::ERROR, syslog_level_num
      end
    end
  end
end
