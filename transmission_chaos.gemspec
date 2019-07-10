# frozen_string_literal: true

require File.join(File.expand_path('lib', __dir__), 'transmission_chaos/version')

Gem::Specification.new do |spec|
  spec.name          = 'transmission_chaos'
  spec.version       = TransmissionChaos::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['ace@haxalot.com']

  spec.summary       = 'Bring chaos to your Transmission daemon'
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/ananace/transmission_chaos'
  spec.license       = 'MIT'

  spec.extra_rdoc_files = %w[README.md LICENSE.txt]
  spec.files            = Dir['{bin,lib}/**/*'] + spec.extra_rdoc_files
  spec.executables      = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.add_dependency 'logging'

  spec.add_development_dependency 'bundler'
  spec.add_development_dependency 'rake'
end
