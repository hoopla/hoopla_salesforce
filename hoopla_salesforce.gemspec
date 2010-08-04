require File.dirname(__FILE__) + "/lib/hoopla_salesforce/version"

$spec = Gem::Specification.new do |s|
  s.name        = "hoopla_salesforce"
  s.version     = HooplaSalesforce::VERSION
  s.summary     = "Some awesome helpers for the salesforce API"
  s.description = "No really, these helpers are awesome"

  s.add_dependency("hoopla-savon", ">= 0.7.6")

  s.files    = Dir["README.md", "lib/**/*.rb"]
  s.has_rdoc = true
  s.authors  = ["Trotter Cashion", "Mat Schaffer"]
  s.email    = "dev@hoopla.net"

  s.homepage = "http://hoopla.net"

  s.rubyforge_project = "nowarning"
end
