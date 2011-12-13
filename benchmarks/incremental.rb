#! /usr/bin/env ruby

require 'rubygems'
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gelf'

TARGET_HOST = 'localhost'
TARGET_PORT = 5140
RANGE = 35000...36000

n = GELF::Notifier.new(TARGET_HOST, TARGET_PORT, 'WAN')
RANGE.each do |size|
  n.notify!('a' * size)
  puts size if (size % 100) == 0
  sleep 0.01
end
