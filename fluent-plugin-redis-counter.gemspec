# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-redis-counter"
  s.version     = "0.2.0"
  s.description = "fluent-plugin-redis-counter is a fluent plugin to count-up/down redis keys."
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Buntaro Okada"]
  s.date        = %q{2013-02-19}
  s.email       = "kbinani.bt@gmail.com"
  s.homepage    = "https://github.com/kbinani/fluent-plugin-redis-counter"
  s.summary     = "Redis counter plugin for fluent"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency %q<fluentd>, ["~> 0.10.0"]
  s.add_dependency %q<redis>, [">= 2.2.2"]
end
