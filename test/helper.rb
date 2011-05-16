require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'
require 'timecop'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'syslog-sd'

class Test::Unit::TestCase
end
