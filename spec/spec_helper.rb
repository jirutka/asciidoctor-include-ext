require 'rspec'

RSpec.configure do |config|
  config.color = true
end

unless RUBY_ENGINE == 'jruby'
  require 'simplecov'

  SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
  SimpleCov.start do
    add_filter '/spec/'
  end
end
