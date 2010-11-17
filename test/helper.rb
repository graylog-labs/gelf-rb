require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'mocha'

begin
  require 'ruby-debug'
rescue LoadError
end

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gelf'

class Test::Unit::TestCase
end
