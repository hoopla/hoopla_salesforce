require 'hoopla_salesforce/utils'

module HooplaSalesforce
  class PackageGenerator
    include Utils

    attr_reader :processed_src
    attr_reader :api_version

    # Right now this only works with making a destructiveChanges.xml
    # Need to add support namespace, etc before using to generate package.xml
    def initialize(processed_src, api_version)
      @processed_src = processed_src
      @api_version = api_version
    end

    def supported_types
      %w(apex_class apex_page custom_tab custom_application apex_trigger)
    end

    def map_files(glob, &block)
      Dir["#{processed_src}/#{glob}"].map(&block)
    end

    def members_for_apex_class
      map_files("classes/*.cls") do |klass|
        data = File.read(klass)
        extract_class_name(data)
      end
    end 

    def members_for_apex_trigger
      map_files("triggers/*.trigger") do |trigger|
        data = File.read(trigger)
        extract_trigger_name(data)
      end
    end

    def members_for_apex_page
      map_files("pages/*.page") do |page|
        File.basename(page, '.page')
      end
    end

    def members_for_custom_tab
      map_files("tabs/*.tab") do |tab|
        File.basename(tab, '.tab')
      end
    end

    def members_for_custom_application
      map_files("applications/*.app") do |app|
        File.read(app).match(/<fullName>([^<]*)<\/fullName>/)[1]
      end
    end

    def empty_package_xml
      <<-EOS.margin
        <?xml version="1.0" encoding="UTF-8"?>
        <Package xmlns="http://soap.sforce.com/2006/04/metadata">
          <version>#{api_version}</version>
        </Package>
      EOS
    end

    def destructive_changes_xml
      <<-EOS.margin
        <?xml version="1.0" encoding="UTF-8"?>
        <Package xmlns="http://soap.sforce.com/2006/04/metadata">
          #{package_types}
          <version>#{api_version}</version>
        </Package>
      EOS
    end

    def package_types
      supported_types.map do |type|
        members = send("members_for_#{type}")
        unless members.empty?
          members_xml = members.map { |m| "<members>#{m}</members>" }.join("\n")
          <<-EOS.margin
            <types>
              #{members_xml}
              <name>#{type.camelize}</name>
            </types>
          EOS
        end
      end.join("\n")
    end

    def generate_destructive_changes
      write_xml "package.xml",            empty_package_xml
      write_xml "destructiveChanges.xml", destructive_changes_xml
      remove_processed_files_for_undeploy
    end

    def write_xml(file, data)
      File.open("#{processed_src}/#{file}", 'w') do |pkg|
        pkg.print data
      end
    end

    def protected_files_for_destruction
      %W(#{processed_src}/package.xml #{processed_src}/destructiveChanges.xml)
    end

    def remove_processed_files_for_undeploy
      Dir["#{processed_src}/*"].each do |file|
        FileUtils.rm_rf(file) unless protected_files_for_destruction.include?(file)
      end 
    end
  end
end
