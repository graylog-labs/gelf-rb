source "https://rubygems.org"

group :development do
  gem "shoulda", "~> 2.11.3"
  gem "jeweler", "~> 2.1.1"
  # Because of a dependency chain jeweler->github_api->oauth2->rack,
  # pin the version: Rack 2.0.x doesn't work on < Ruby 2.2
  gem 'rack', '< 2.0'
  gem "mocha", "~> 1.1.0"
  gem "test-unit", "~> 3.2.0"
end
