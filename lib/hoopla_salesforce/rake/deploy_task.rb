require 'hoopla_salesforce/rake/base_task'

module HooplaSalesforce
  module Rake
    class DeployTask < BaseTask
      # Your project root. Defaults to 'src'
      attr_accessor :src

      # The location of the zip file generated for deployment. Defaults to 'deploy.zip'
      attr_accessor :deployfile

      def initialize(name=:deploy)
        @deploy_file = "deploy.zip"
        @src = 'src'
        super
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
