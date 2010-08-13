require File.dirname(__FILE__) + "/lib/hoopla_salesforce/info"

$spec = Gem::Specification.new do |s|
  s.name        = HooplaSalesforce.name
  s.version     = HooplaSalesforce.version
  s.summary     = HooplaSalesforce.summary
  s.description = HooplaSalesforce.description

  s.add_dependency("hoopla-savon", ">= 0.7.6")
  s.add_dependency("rubyzip",      ">= 0.9.4")
  s.add_dependency('commander',    '>= 4.0.3')
  s.add_dependency('erubis',       '>= 2.6.6')

  s.files       = Dir["README.md", "bin/*", "lib/**/*.rb"]
  s.bindir      = 'bin'
  s.executables = 'hoopla_salesforce'
  s.has_rdoc    = true
  s.authors     = ["Trotter Cashion", "Mat Schaffer"]
  s.email       = "dev@hoopla.net"

  s.homepage = "http://hoopla.net"

  s.rubyforge_project = "nowarning"
end
