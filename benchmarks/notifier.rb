require 'benchmark'

require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gelf'

TARGET_HOST = 'localhost'
TARGET_PORT = 12345
LAN_WAN = 'LAN'
DEFAULT_OPTIONS = { :host => 'localhost' }
TIMES = 10000
HASH = { 'short_message' => 'message' }

notifier = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, LAN_WAN, DEFAULT_OPTIONS)

notifier_with_cache = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, LAN_WAN, DEFAULT_OPTIONS)
notifier_with_cache.cache_size = 100

Benchmark.bmbm do |b|
  b.report('  no cache') { TIMES.times { notifier.notify!(HASH) } }
  b.report('with cache') { TIMES.times { notifier_with_cache.notify!(HASH) } }
end
raise SecurityError.new("Results are WRONG!") unless notifier_with_cache.instance_variable_get('@cache').empty?
