require 'rake'
require 'rake/tasklib'
require 'hoopla_salesforce'

module HooplaSalesforce
  module Rake
    class BaseTask < ::Rake::TaskLib
      # The name for the task and any dependencies.
      attr_accessor :name
     
      # Your salesforce username 
      attr_accessor :username

      # Your salesforce password
      attr_accessor :password

      # Your salesforce API token, which will get concatenated onto your password.
      attr_accessor :token

      # Path to your enterprise WSDL. Defaults to value of HooplaSalesforce.enterprise_wsdl.
      attr_accessor :enterprise_wsdl

      # Path to your metadata WSDL. Defaults to value of HooplaSalesforce.metadata_wsdl.
      attr_accessor :metadata_wsdl

      def initialize(name)
        @name = name
        @enterprise_wsdl = HooplaSalesforce.enterprise_wsdl
        @metadata_wsdl = HooplaSalesforce.metadata_wsdl

        yield self if block_given?
        define
      end
    end
  end
end
