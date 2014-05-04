# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-mobileid/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-mobileid"
  s.version     = Omniauth::Mobileid::VERSION
  s.authors     = ["Tarmo Talu"]
  s.email       = ["tarmo.talu@gmail.com"]
  s.homepage    = "http://github.com/tarmotalu/omniauth-mobileid"
  s.summary     = %q{OmniAuth strategy for Estonian Mobile-ID}
  s.description = %q{OmniAuth strategy for Estonian Mobile-ID}

  s.rubyforge_project = "omniauth-mobileid"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'omniauth-oauth', '~> 1.0'
  s.add_dependency 'digidoc_client', '~> 0.2'
end
