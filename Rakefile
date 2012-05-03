# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'rake'
require 'jeweler'

Jeweler::Tasks.new do |gem|
  gem.name = "gelf"
  gem.summary = 'Library to send GELF messages to Graylog2 logging server.'
  gem.description = 'Library to send GELF messages to Graylog2 logging server. Supports plain-text, GELF messages and exceptions.'
  gem.email = "alexey.palazhchenko@gmail.com"
  gem.homepage = "http://github.com/Graylog2/gelf-rb"
  gem.authors = ["Alexey Palazhchenko", "Lennart Koopmann"]
  # dependencies defined in Gemfile
end

task :default => :test

Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.rcov_opts << '--exclude gem'
    test.verbose = true
  end
rescue LoadError
  # nothing
end

require 'rdoc/task'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gelf #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
