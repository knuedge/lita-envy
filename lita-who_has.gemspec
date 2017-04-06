Gem::Specification.new do |spec|
  spec.name          = 'lita-who_has'
  spec.version       = '0.2.0'
  spec.authors       = ['Jonathan Gnagy']
  spec.email         = ['jgnagy@knuedge.com']
  spec.description   = 'A more generic lita-envy for who owns things via lita'
  spec.summary       = 'Record and retrieve information about things'
  spec.homepage      = 'https://github.com/knuedge/lita-who_has'
  spec.license       = 'MIT'
  spec.metadata      = { 'lita_plugin_type' => 'handler' }

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.required_ruby_version = '~> 2.2'

  spec.add_runtime_dependency 'lita', '>= 4.6'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'rspec', '>= 3.0.0'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'coveralls'
  spec.add_development_dependency 'byebug'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'travis', '~> 1.8'
end
