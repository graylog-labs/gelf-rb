require 'rake'

begin
  require 'ci/reporter/rake/test_unit'
rescue LoadError
  # nothing
end

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name = "gelf"
    gem.summary = 'Library to send GELF messages to Graylog logging server.'
    gem.description = 'Library to send GELF messages to Graylog logging server. Supports plain-text, GELF messages and exceptions via UDP and TCP.'
    gem.email = "mail@marcusilgner.com"
    gem.homepage = "http://github.com/Graylog2/gelf-rb"
    gem.authors = ["Alexey Palazhchenko", "Lennart Koopmann", "Zac Sprackett", "Marcus Ilgner"]
    gem.add_dependency "json"
    gem.licenses = ["MIT"]
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
rescue LoadError => e
  puts e
  abort "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.rcov_opts << '--exclude gem'
    test.verbose = true
  end
rescue LoadError => e
  task :rcov do
    puts e
    abort "rcov is not available. Run: gem install rcov"
  end
end

#require 'rake/rdoctask'
#Rake::RDocTask.new do |rdoc|
#  version = File.exist?('VERSION') ? File.read('VERSION') : ""
#
#  rdoc.rdoc_dir = 'rdoc'
#  rdoc.title = "gelf #{version}"
#  rdoc.rdoc_files.include('README*')
#  rdoc.rdoc_files.include('lib/**/*.rb')
#end
