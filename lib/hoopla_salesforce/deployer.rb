require 'base64'
require 'savon'
require 'hoopla_salesforce/text_reporter'

Savon::Request.logger = Logger.new(STDOUT)
Savon::Request.logger.level = Logger::WARN
Savon::Request.log_level = :debug

module HooplaSalesforce
  # Deploys and retreives zip files from salesforce using the metadata API.
  # Use ENV['LOGIN_HOST'] = 'test.salesforce.com' to use this on sandbox organizations.
  class Deployer
    attr_accessor :client, :metaclient, :header,
                  :username, :password, :token

    def initialize(username, password, token, enterprise_wsdl, metadata_wsdl)
      @username = username
      @password = password
      @token    = token
      @enterprise_wsdl = enterprise_wsdl
      @metadata_wsdl   = metadata_wsdl
    end

    def login
      build_clients
      set_certs
      setup_metaclient_and_store_header
    end

    def build_clients
      @client     = Savon::Client.new @enterprise_wsdl
      @metaclient = Savon::Client.new @metadata_wsdl
    end

    def set_certs
      # TODO figure out how to get Savon to validate SF's cert
      [@client, @metaclient].each { |c| c.request.http.ssl_client_auth(:verify_mode => OpenSSL::SSL::VERIFY_NONE) }
    end

    def setup_metaclient_and_store_header
      client.wsdl.soap_endpoint.host = ENV['LOGIN_HOST'] if ENV['LOGIN_HOST']

      response = client.login do |soap, wsse|
        soap.body = { "wsdl:username" => username, "wsdl:password" => password + token}
      end.to_hash[:login_response][:result]

      metaclient.wsdl.soap_endpoint = response[:metadata_server_url]

      @header = { "wsdl:SessionHeader" => { "wsdl:sessionId" => response[:session_id] } }
    end

    def deploy(zipfile, options = {})
      login

      data = Base64.encode64(File.read(zipfile))

      response = metaclient.deploy do |soap, wsse|
        soap.header = header
        soap.body = { "wsdl:ZipFile" => data,
                      "wsdl:DeployOptions" => options,
                      :order! => ['wsdl:ZipFile', 'wsdl:DeployOptions']
                    }
      end.to_hash[:deploy_response][:result]
   
      puts "Deployment requested, awaiting completion of job #{response[:id]}..." 
      while !response[:done]
        begin
          response = metaclient.check_status do |soap, wsse|
            soap.header = header
            soap.body = { "wsdl:asyncProcessId" => response[:id] }
          end.to_hash[:check_status_response][:result]
        rescue Timeout::Error
        end
      end 

      response = metaclient.check_deploy_status do |soap, wsse|
        soap.header = header
        soap.body = { "wsdl:asyncProcessId" => response[:id] }
      end.to_hash[:check_deploy_status_response][:result]

      error_out unless TextReporter.new(response).report
    end

    def error_out
      raise "Deployment errors. See report for details."
    end

    def retrieve(request)
      login

      response = metaclient.retrieve do |soap, wsse|
        soap.header = @header
        soap.body = { "wsdl:retrieveRequest" => request }
      end.to_hash[:retrieve_response][:result]
 
      puts "Retrieve requested, awaiting completion of job #{response[:id]}..." 
      while !response[:done]
        response = metaclient.check_status do |soap, wsse|
          soap.header = @header
          soap.body = { "wsdl:asyncProcessId" => response[:id] }
        end.to_hash[:check_status_response][:result]
      end
      
      response = metaclient.check_retrieve_status do |soap, wsse|
        soap.header = @header
        soap.body = { "wsdl:asyncProcessId" => response[:id] }
      end.to_hash[:check_retrieve_status_response][:result]
      
      File.open('retrieved.zip', 'w') { |f| f.print Base64.decode64(response[:zip_file]) }
      puts "Wrote retrieved contents to retrieved.zip."
    end
  end
end
