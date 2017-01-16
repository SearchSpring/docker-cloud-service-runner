# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'docker_cloud_service_runner/version'

Gem::Specification.new do |spec|
  spec.name          = "docker_cloud_service_runner"
  spec.version       = DockerCloudServiceRunner::VERSION
  spec.authors       = ["Tyler Ruppert"]
  spec.email         = ["tyler@searchspring.com"]

  spec.summary       = %q{Service Runner for Docker Cloud}
  spec.homepage      = "https://github.com/SearchSpring/docker-cloud-service-runner"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
