#! /usr/bin/env ruby

puts "Loading..."

require 'benchmark'
require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'syslog-sd'

puts "Generating random data..."
srand(1)
RANDOM_DATA = ('A'..'z').to_a
k3_message = (1..3*1024).map { RANDOM_DATA[rand(RANDOM_DATA.count)] }.join

TARGET_HOST = 'localhost'
TARGET_PORT = 12201
DEFAULT_OPTIONS = { '_host' => 'localhost' }
TIMES = 5000

SHORT_HASH = { 'short_message' => 'message' }
LONG_HASH  = { 'short_message' => 'message', 'long_message' => k3_message }


notifier = SyslogSD::Notifier.new(TARGET_HOST, TARGET_PORT, DEFAULT_OPTIONS)

# to create mongo collections, etc.
notifier.notify!(LONG_HASH)
sleep(5)

puts "Sending #{TIMES} notifications...\n"
tms = Benchmark.bm(25) do |b|
  b.report('short data') { TIMES.times { notifier.notify!(SHORT_HASH) } }
  sleep(5)
  b.report('long data ') { TIMES.times { notifier.notify!(LONG_HASH) } }
end
