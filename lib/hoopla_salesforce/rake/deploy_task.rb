require 'rake'
require 'rake/tasklib'

require 'hoopla_salesforce'

module HooplaSalesforce
  module Rake
    class DeployTask < ::Rake::TaskLib
      # The name for the task and any dependencies. Defaults to 'deploy'.
      attr_accessor :name
     
      # Your salesforce username 
      attr_accessor :username

      # Your salesforce password
      attr_accessor :password

      # Your salesforce API token, which will get concatenated onto your password.
      attr_accessor :token

      # Your project root. Defaults to 'src'
      attr_accessor :src

      # Path to your enterprise WSDL. Defaults to value of HooplaSalesforce.enterprise_wsdl.
      attr_accessor :enterprise_wsdl

      # Path to your metadata WSDL. Defaults to value of HooplaSalesforce.metadata_wsdl.
      attr_accessor :metadata_wsdl

      # The location of the zip file generated for deployment. Defaults to 'deploy.zip'
      attr_accessor :deployfile

      def initialize(name=:deploy)
        @name = name
        @deployfile = "deploy.zip"
        @src = 'src'
        @enterprise_wsdl = HooplaSalesforce.enterprise_wsdl
        @metadata_wsdl = HooplaSalesforce.metadata_wsdl

        yield self if block_given?
        define
      end

      def define
        desc "Deploy to salesforce"
        task name do
          make_zipfile
          require 'hoopla_salesforce/deployer'
          HooplaSalesforce::Deployer.new(username, password, token, enterprise_wsdl, metadata_wsdl).deploy(deployfile)
        end
      end

      def make_zipfile
        require 'zip/zip'
        rm_f deployfile
        Zip::ZipFile.open(deployfile, Zip::ZipFile::CREATE) do |zip|
          Dir["#{src}/**/*"].each do |file|
            zip.add(file, file)
          end 
        end
      end
    end
  end
end
