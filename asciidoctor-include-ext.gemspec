require File.expand_path('../lib/asciidoctor/include_ext/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'asciidoctor-include-ext'
  s.version     = Asciidoctor::IncludeExt::VERSION
  s.author      = 'Jakub Jirutka'
  s.email       = 'jakub@jirutka.cz'
  s.homepage    = 'https://github.com/jirutka/asciidoctor-include-ext'
  s.license     = 'MIT'

  s.summary     = "Asciidoctor's standard include::[] processor reimplemented as an extension"
  s.description = <<EOF
This is a reimplementation of the Asciidoctor's built-in (pre)processor for the
include::[] directive in extensible and more clean way. It provides the same
features, but you can easily adjust it or extend for your needs. For example,
you can change how it loads included files or add another ways how to select
portions of the document to include.
EOF

  s.files       = Dir['lib/**/*', '*.gemspec', 'LICENSE*', 'README*']
  s.has_rdoc    = 'yard'

  s.required_ruby_version = '>= 2.1'

  s.add_runtime_dependency 'asciidoctor', '~> 1.5.6'

  s.add_development_dependency 'corefines', '~> 1.11'
  s.add_development_dependency 'kramdown', '~> 1.16'
  s.add_development_dependency 'rake', '~> 12.0'
  s.add_development_dependency 'rspec', '~> 3.7'
  s.add_development_dependency 'rubocop', '~> 0.51.0'
  s.add_development_dependency 'simplecov', '~> 0.15'
  s.add_development_dependency 'yard', '~> 0.9'
end
