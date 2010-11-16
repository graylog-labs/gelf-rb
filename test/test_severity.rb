require 'helper'

class TestSeverity < Test::Unit::TestCase
  should "define constants for standard syslog levels" do
    GELF::LEVELS.each do |k, v|
      assert_equal v, GELF.const_get(k.to_s.upcase)
    end
  end

  should "define constants for aliased syslog levels" do
    GELF::LEVELS_EXT.each do |k, v|
      assert_equal GELF.const_get(v.to_s.upcase), GELF.const_get(k.to_s.upcase)
    end
  end
end
