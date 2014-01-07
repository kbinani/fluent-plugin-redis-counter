# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-redis-multi-type-counter"
  s.version     = "0.1.0"
  s.description = "fluent-plugin-redis-multi-type-counter is a fluent plugin to count-up/down redis keys, hash keys, zset keys"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jungtaek Lim"]
  s.date        = %q{2014-01-07}
  s.email       = "kabhwan@gmail.com"
  s.homepage    = "https://github.com/heartsavior/fluent-plugin-redis-multi-type-counter"
  s.summary     = "Redis multi type counter plugin for fluent"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency %q<fluentd>, ["~> 0.10.0"]
  s.add_dependency %q<redis>, [">= 2.2.2"]
end
