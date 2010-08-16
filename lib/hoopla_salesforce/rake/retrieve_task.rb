require 'hoopla_salesforce/rake/base_task'

module HooplaSalesforce
  module Rake
    class RetrieveTask < BaseTask
      # The format of the retrieve request. Defaults to:
      #   { "wsdl:unpackaged" => { "wsdl:types" =>
      #     [{ "wsdl:members" => "*", "wsdl:name" => "ApexClass" }]
      #   }}
      #
      # If your code is in a salesforce package, you can specify:
      #   { "wsdl:packageNames" => ["Your Package Name"] }
      attr_accessor :request

      def initialize(name=:retrieve)
        @request = { "wsdl:unpackaged" => { "wsdl:types" =>
                     [{ "wsdl:members" => "*", "wsdl:name" => "ApexClass" }]
                   }}
        super
      end

      def define
        namespace :hsf do
          desc "Retrieve all apex classes from salesforce.com"
          task name do
            require 'hoopla_salesforce/deployer'
            HooplaSalesforce::Deployer.new(username, password, token, enterprise_wsdl, metadata_wsdl).retrieve(request)
          end
        end
      end
    end
  end
end

