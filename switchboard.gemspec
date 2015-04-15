Gem::Specification.new do |s|
  s.name        = 'switchboard'
  s.version     = '0.1.13'
  s.date        = '2015-04-06'
  s.summary     = "Switchboard Ruby Wrapper"
  s.description = "A ruby wrapper to talk to Switchboard"
  s.authors     = ["Leandro Ostera"]
  s.email       = 'leandro@ostera.io'
  s.files       = ["lib/switchboard.rb"]
  s.homepage    = 'https://github.com/ostera/switchboard.rb'
  s.license     = 'MIT'

  s.add_runtime_dependency "mail", ["~> 2.6"]
  s.add_runtime_dependency "faye-websocket", ["~> 0.9"]
end
