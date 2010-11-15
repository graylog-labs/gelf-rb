require 'rubygems'
require 'rake'

begin
  gem 'jeweler', '~> 1.4.0' # https://github.com/technicalpickles/jeweler/issues/issue/150
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gelf"
    gem.summary = 'Library to send GELF messages to Graylog2 logging server'
    gem.description = 'Suports plain-text, GELF messages and exceptions.'
    gem.email = "lennart@socketfeed.com"
    gem.homepage = "http://github.com/Graylog2/gelf-rb"
    gem.authors = ["Alexey Palazhchenko", "Lennart Koopmann"]
    gem.add_dependency "json"
    gem.add_development_dependency "shoulda"
    gem.add_development_dependency "mocha"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

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
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: gem install rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gelf #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
