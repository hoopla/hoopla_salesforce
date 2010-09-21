require 'hoopla_salesforce/rake/base_task'
require 'hoopla_salesforce/ext/string'
require 'hoopla_salesforce/template_processor'
require 'hoopla_salesforce/utils'

module HooplaSalesforce
  module Rake

    # Deploys your project to salesforce.
    #
    # Peforms some nice processing as well including:
    #   - Replaces any occurance of __NAMESPACE__ in your code with the appropriate namespace
    #     declaration if you set a namespace on the task
    #   - Zips up any folders found in src/resources as src/staticresources/#{folder}.resource.
    #     This allows you to only keep the raw assets in your project
    class DeployTask < BaseTask
      include Utils

      # Your project root. Defaults to 'src'
      attr_accessor :src

      # The location of the zip file generated for deployment. Defaults to 'deploy.zip'
      attr_accessor :deploy_file

      # The namespace you're deploying the package to. This will convert all
      # occurrences of __NAMESPACE__ in your source code to your_namespace__.
      # It's helpful if you're deploying to both your production org (that has
      # the namespaced package) and a dev org (that does not have one).
      #
      # default - nil
      attr_accessor :package_namespace

      # The directory in which to store processed source files.
      # Defaults to #{src}-processed
      attr_accessor :processed_src

      # Which file to load before processing templates. Default: lib/template_helper.rb
      # To have this file inject methods into the HooplaSalesforce::TemplateProcessor,
      # be sure to include your module in HooplaSalesforce::TemplateProcessor::VisualForce or 
      # HooplaSalesforce::TemplateProcessor::TestPage at the bottom of your template_helper
      # file.
      attr_accessor :template_helper

      def initialize(name=:production)
        @deploy_file       = "deploy.zip"
        @src               = 'src'
        @package_namespace = nil
        @template_helper   = 'lib/template_helper.rb'
        super
        @package_namespace  += "__" if @package_namespace
        @processed_src     ||= "#{src}-processed" 
      end

      def clean_namespace
        package_namespace.sub(/__$/, '') if package_namespace
      end

      def define
        if name.is_a? Hash
          task_name = name.keys.first
          dependencies = name[task_name]
        else
          task_name = name
          dependencies = []
        end

        namespace :hsf do
          namespace :undeploy do
            desc "Undeploy all components in #{src} from salesforce"
            task task_name => dependencies do
              process_source
              require 'hoopla_salesforce/package_generator'
              PackageGenerator.new(processed_src, api_version).generate_destructive_changes
              make_zipfile
              deploy_zipfile
            end
          end

          namespace :deploy do
            desc "Deploy to salesforce"
            task task_name => dependencies do
              process_source
              make_meta_xmls
              make_zipfile
              deploy_zipfile
            end
          end

          namespace :testpages do
            desc "Renders any page templates as test pages in #{processed_src}/pages-test"
            task task_name => dependencies do
              mkdir_p "#{src}/pages-test"
              make_pages do |template|
                HooplaSalesforce::TemplateProcessor::TestPage.new(src, template)
              end
            end
          end
        end
      end

      def test_names
        if ENV['TEST_NAMES']
          ENV['TEST_NAMES'].split(',')
        else
          Dir["#{processed_src}/classes/*.cls"].inject([]) do |names, f|
            body = File.read(f)
            if body =~ /(testMethod|@isTest)/ && name = extract_class_name(body)
              names << name
            else
              names
            end
          end
        end
      end

      def test_options
        unless test_names.empty?
          test_names.map! { |n| "#{clean_namespace}.#{n}" } if package_namespace
          { "wsdl:runTests" => test_names }
        end
      end

      def api_version
        return @api_version if @api_version
        File.read("#{src}/package.xml") =~ /<version>(.*)<\/version>/i
        @api_version = $1
      end

      def make_pages
        require template_helper if File.exist?(template_helper)

        Dir["#{src}/pages/*.page.erb"].each do |template|
          yield template
        end
      end

      def preprocess_files
        require template_helper if File.exist?(template_helper)

        Dir["#{processed_src}/**/*.erb"].each do |template|
          yield template
        end
      end

      def make_meta(glob)
        Dir["#{processed_src}/#{glob}"].each do |file|
          meta = "#{file}-meta.xml"
          next if file =~ /-meta\.xml$/ || File.exist?(meta)
          File.open(meta, 'w') do |f|
            f.print yield(file)
          end
        end
      end

      def make_meta_xmls
        make_meta "classes/*.cls" do |klass|
          <<-EOS.margin
            <?xml version="1.0" encoding="UTF-8"?>
            <ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
              <apiVersion>#{api_version}</apiVersion>
            </ApexClass>
          EOS
        end

        make_meta "pages/*.page" do |page|
          <<-EOS.margin
            <?xml version="1.0" encoding="UTF-8"?>
            <ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
              <apiVersion>#{api_version}</apiVersion>
              <label>#{File.basename(page, '.page')}</label>
            </ApexClass>
          EOS
        end

        make_meta "documents/**/*" do |doc|
          if File.directory?(doc)
            m = <<-EOS.margin
              <?xml version="1.0" encoding="UTF-8"?>
              <DocumentFolder xmlns="http://soap.sforce.com/2006/04/metadata">
                <name>#{File.basename(doc)}</name>
                <accessType>Public</accessType>
                <publicFolderAccess>ReadOnly</publicFolderAccess>
              </DocumentFolder>
            EOS
          else
            <<-EOS.margin
              <?xml version="1.0" encoding="UTF-8"?>
              <Document xmlns="http://soap.sforce.com/2006/04/metadata">
                <internalUseOnly>false</internalUseOnly>
                <name>#{File.basename(doc)}</name>
                <public>true</public>
                <description>A document</description>
              </Document>
            EOS
          end
        end

        make_meta "staticresources/*.resource" do |resource|
          <<-EOS.margin
            <?xml version="1.0" encoding="UTF-8"?>
            <StaticResource xmlns="http://soap.sforce.com/2006/04/metadata">
              <cacheControl>Private</cacheControl>
              <contentType>application/zip</contentType>
              <description>A static resource</description>
            </StaticResource>
          EOS
        end

        make_meta "triggers/*.trigger" do |trigger|
          <<-EOS.margin
            <?xml version="1.0" encoding="UTF-8"?>
            <ApexTrigger xmlns="http://soap.sforce.com/2006/04/metadata">
                <apiVersion>#{api_version}</apiVersion>
                <status>Active</status>
            </ApexTrigger>
          EOS
        end
      end

      def make_resources
        require 'zip/zip'

        staticresources = "#{processed_src}/staticresources"
        mkdir staticresources
        
        Dir["#{processed_src}/resources/*"].each do |f|
          next unless File.directory?(f)
          resourcename = File.basename(f) + ".resource"
          resourcefile = "#{staticresources}/#{resourcename}"
          Zip::ZipFile.open(resourcefile, Zip::ZipFile::CREATE) do |zip|
            Dir["#{f}/**/*"].each do |file|
              zip.add(file.sub("#{f}/", ''), file)
            end
          end

          source_meta = "#{f}.resource-meta.xml"
          cp source_meta, "#{resourcefile}-meta.xml" if File.exist?(source_meta)
        end
      end

      def make_zipfile
        require 'zip/zip'
        rm_f deploy_file
        Zip::ZipFile.open(deploy_file, Zip::ZipFile::CREATE) do |zip|
          Dir["#{processed_src}/**/*"].each do |file|
            zip.add(file.sub(/^#{processed_src}/, src), file)
          end 
        end
      end

      def deploy_zipfile
        require 'hoopla_salesforce/deployer'
        deployer = HooplaSalesforce::Deployer.new(username, password, token, enterprise_wsdl, metadata_wsdl)
        if ENV['WEB_TESTS']
          require 'hoopla_salesforce/web_agent'
          deployer.deploy(deploy_file)
          WebAgent.new(username, password).run_tests(test_names, clean_namespace)
        else
          deployer.deploy(deploy_file, test_options)
        end
      end

      def substitute_namespaces
        Dir["#{processed_src}/**/*"].each do |f|
          next if File.directory?(f)
          system %Q|ruby -i -n -e 'print $_.gsub("__NAMESPACE__", "#{package_namespace}")' "#{f}"|
        end

        if package_namespace
          system %Q|ruby -i -n -e 'print $_.gsub("#{package_namespace}", "#{clean_namespace}")' "#{processed_src}/package.xml"|
        end
      end

      def process_source
        rm_rf processed_src
        cp_r src, processed_src
        make_resources
        make_pages do |template|
          HooplaSalesforce::TemplateProcessor::VisualForce.new(processed_src, template)
          rm template.sub(src, processed_src)
        end

        preprocess_files do |template|
          HooplaSalesforce::TemplateProcessor::Generic.new(processed_src, template)
          rm template
        end

        substitute_namespaces
      end
    end
  end
end
