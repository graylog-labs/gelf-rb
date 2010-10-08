# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{gelf}
  s.version = "0.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.2") if s.respond_to? :required_rubygems_version=
  s.authors = ["Lennart Koopmann"]
  s.date = %q{2010-10-08}
  s.description = %q{Library to send Graylog2 Extended Log Format (GELF) messages}
  s.email = %q{lennart@socketfeed.com}
  s.extra_rdoc_files = ["lib/gelf.rb"]
  s.files = ["Rakefile", "lib/gelf.rb", "Manifest", "gelf.gemspec"]
  s.homepage = %q{http://www.graylog2.org/}
  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "Gelf"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{gelf}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Library to send Graylog2 Extended Log Format (GELF) messages}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
