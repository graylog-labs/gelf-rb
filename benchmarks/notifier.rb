require 'benchmark'

require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gelf'

srand(1)
RANDOM_DATA = ('A'..'z').to_a
k1_message = (0..1024).map { RANDOM_DATA[rand(RANDOM_DATA.count)] }.join

TARGET_HOST = 'localhost'
TARGET_PORT = 12201
DEFAULT_OPTIONS = { :host => 'localhost' }
TIMES = 5000

SHORT_HASH = { 'short_message' => 'message' }
LONG_HASH = { 'short_message' => k1_message }


notifier_nc_lan = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'LAN', DEFAULT_OPTIONS)
notifier_nc_wan = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'WAN', DEFAULT_OPTIONS)
notifier_c_lan  = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'LAN', DEFAULT_OPTIONS)
notifier_c_wan  = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'WAN', DEFAULT_OPTIONS)
notifier_c_lan.cache_size = notifier_c_wan.cache_size = 100

puts "Sending #{TIMES} notifications..."
tms = Benchmark.bmbm do |b|
  b.report('lan,   no cache, short data') { TIMES.times { notifier_nc_lan.notify!(SHORT_HASH) } }
  b.report('lan, with cache, short data') { TIMES.times { notifier_c_lan.notify!(SHORT_HASH) } }
  b.report('wan,   no cache, short data') { TIMES.times { notifier_nc_wan.notify!(SHORT_HASH) } }
  b.report('wan, with cache, short data') { TIMES.times { notifier_c_wan.notify!(SHORT_HASH) } }

  b.report('lan,   no cache,  long data') { TIMES.times { notifier_nc_lan.notify!(LONG_HASH) } }
  b.report('lan, with cache,  long data') { TIMES.times { notifier_c_lan.notify!(LONG_HASH) } }
  b.report('wan,   no cache,  long data') { TIMES.times { notifier_nc_wan.notify!(LONG_HASH) } }
  b.report('wan, with cache,  long data') { TIMES.times { notifier_c_wan.notify!(LONG_HASH) } }
end

raise SecurityError.new("Results are WRONG!") unless notifier_c_lan.instance_variable_get('@cache').empty?
