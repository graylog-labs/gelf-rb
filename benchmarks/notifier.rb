#! /usr/bin/env ruby

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
DEFAULT_OPTIONS = { 'host' => 'localhost' }
TIMES = 5000

SHORT_HASH = { 'short_message' => 'message' }
LONG_HASH = { 'short_message' => 'short message', 'long_message' => k1_message, 'user_id' => rand(10000)}


notifier_lan = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'LAN', DEFAULT_OPTIONS)
notifier_wan = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'WAN', DEFAULT_OPTIONS)

puts "Sending #{TIMES} notifications..."
tms = Benchmark.bmbm do |b|
  b.report('lan, short data') { TIMES.times { notifier_lan.notify!(SHORT_HASH) } }
  b.report('wan, short data') { TIMES.times { notifier_wan.notify!(SHORT_HASH) } }
  b.report('lan,  long data') { TIMES.times { notifier_lan.notify!(LONG_HASH) } }
  b.report('wan,  long data') { TIMES.times { notifier_wan.notify!(LONG_HASH) } }
end
