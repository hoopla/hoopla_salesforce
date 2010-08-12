require 'fileutils'

module HooplaSalesforce
  class Skeleton
    include FileUtils

    attr_reader :directory

    def initialize(directory)
      @directory = directory
    end

    def mkdir_p(dir='')
      super directory + dir
    end

    def create
      puts "Creating a skeleton in #{directory}"
      %w(applications classes objects pages resources tabs triggers).each do |dir|
        mkdir_p "/src/#{dir}"
      end
      mkdir_p '/lib'
      make_package_xml
      make_rakefile
      make_gitignore
      followup_instructions
    end

    def make_package_xml
      File.open("#{directory}/src/package.xml", 'w') do |pkg|
        pkg.print <<-EOS.gsub(' ' * 10, '')
          <?xml version="1.0" encoding="UTF-8"?>
          <Package xmlns="http://soap.sforce.com/2006/04/metadata">
            <fullName></fullName>
            <apiAccessLevel>Unrestricted</apiAccessLevel>
            <description></description>
            <namespacePrefix>__NAMESPACE__</namespacePrefix>
            <types>
              <members>*</members>
              <name>ApexClass</name>
            </types>
            <types>
              <members>*</members>
              <name>ApexPage</name>
            </types>
            <types>
              <members>*</members>
              <name>ApexTrigger</name>
            </types>
            <types>
              <members>*</members>
              <name>CustomApplication</name>
            </types>
            <types>
              <members>*</members>
              <name>CustomObject</name>
            </types>
            <types>
              <members>*</members>
              <name>CustomField</name>
            </types>
            <types>
              <members>*</members>
              <name>ValidationRule</name>
            </types>
            <types>
              <members>*</members>
              <name>CustomTab</name>
            </types>
            <types>
              <members>*</members>
              <name>StaticResource</name>
            </types>
            <version>18.0</version>
          </Package>
        EOS
      end
    end

    def make_rakefile
      File.open("#{directory}/Rakefile", 'w') do |rakefile|
        rakefile.print <<-EOS.gsub(' ' * 10, '')
          require 'hoopla_salesforce/rake'
          
          HooplaSalesforce.enterprise_wsdl = "lib/enterprise.xml"
          HooplaSalesforce.metadata_wsdl   = "lib/metadata.xml"
          
          namespace :deploy do
            HooplaSalesforce::Rake::DeployTask.new(:development) do |t|
              t.username = "you@development.org"
              t.password = "yourpassword"
              t.token    = "your security token"
            end
          end
        EOS
      end
    end

    def make_gitignore
      File.open("#{directory}/.gitignore", 'w') do |gitignore|
        gitignore.print <<-EOS.gsub(' ' * 10, '')
          src-processed
          deploy.zip
        EOS
      end
    end

    def followup_instructions
      puts
      puts "-" * 80
      puts " All done. Now you need to download your WSDL files into your project:"
      puts
      puts "   Enterprise WSDL: #{directory}/lib/enterprise.xml"
      puts "   Metadata WSDL:   #{directory}/lib/metadata.xml"
      puts
      puts "-" * 80
    end
  end
end
