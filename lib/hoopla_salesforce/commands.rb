require 'hoopla_salesforce/info'
require 'commander/import'
require 'hoopla_salesforce/ext/commander'

program :name,        HooplaSalesforce.name
program :version,     HooplaSalesforce.version
program :description, HooplaSalesforce.summary

default_command :help

command "init" do |c|
  c.syntax      = '[options] <directory>'
  c.summary     = 'Creates a skeleton app.'
  c.description = 'Creates a skeleton Salesforce.com app in the specified directory.'

  c.action do |args, options|
    directory = args.first or raise "Directory name required."
    require 'hoopla_salesforce/skeleton'
    HooplaSalesforce::Skeleton.new(directory).create
  end
end
