require 'rake'

begin
  require 'ci/reporter/rake/test_unit'
rescue LoadError
  # nothing
end

begin
  require 'jeweler'

  Jeweler::Tasks.new do |gem|
    gem.name = "syslog-sd"
    gem.summary = 'Library to send syslog messages over UDP to logging server such as Graylog2. Supports Structured Data elements as defined by RFC 5424.'
    gem.description = 'Super-Duper library to send syslog messages over UDP to logging server such as Graylog2. ' +
                      'Supports Structured Data elements as defined by RFC 5424.'
    gem.email = "alexey.palazhchenko@gmail.com"
    gem.homepage = "http://github.com/AlekSi/syslog-sd-rb"
    gem.authors = ["Alexey Palazhchenko", "Lennart Koopmann"]
    gem.add_development_dependency "shoulda"
    gem.add_development_dependency "mocha"
    gem.add_development_dependency "timecop"
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

task :test => :check_dependencies
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

begin
  gem 'ruby_parser', '~> 2.0.6'
  gem 'activesupport', '~> 3.0.0'
  gem 'metric_fu', '~> 2.1.1'
  require 'metric_fu'

  MetricFu::Configuration.run do |config|
    # Saikuro is useless
    config.metrics -= [:saikuro]

    config.flay     = { :dirs_to_flay  => ['lib'],
                        :minimum_score => 10  }
    config.flog     = { :dirs_to_flog  => ['lib'] }
    config.reek     = { :dirs_to_reek  => ['lib'] }
    config.roodi    = { :dirs_to_roodi => ['lib'] }
    config.rcov     = { :environment => 'test',
                        :test_files => ['test/test_*.rb'],
                        :rcov_opts => ["-I 'lib:test'",
                                       "--sort coverage",
                                       "--no-html",
                                       "--text-coverage",
                                       "--no-color",
                                       "--exclude /test/,/gems/"]}
    config.graph_engine = :gchart
  end

rescue LoadError, NameError => e
  desc 'Generate all metrics reports'
  task :'metrics:all' do
    puts e.inspect
    # puts e.backtrace
    abort "metric_fu is not available. Run: gem install metric_fu"
  end
end

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "syslog-sd #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
