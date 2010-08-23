require 'hoopla_salesforce/eruby'

module HooplaSalesforce
  class TemplateProcessor
    class Base
      include HooplaSalesforce::CaptureHelper

      attr_reader :src, :base, :file
      def initialize(src, file)
        @src     = src
        @base    = File.basename(file, '.erb')
        @file    = file
        template = Eruby.new(File.read(file))

        File.open(output_file, 'w') do |f|
          f.print template.result(binding)
        end
      end

      def each_resource_file(files, extension)
        files.map do |file|
          file += ".#{extension}" unless extension =~ /\.#{extension}$/
          yield file
        end.join("\n")
      end
    end

    class Generic < Base
      def output_file
        file.sub(/\.erb$/, '')
      end
    end

    class VisualForce < Base
      def page(opts={})
        params = opts.map { |key, val| %Q|#{key}="#{val}"| }.join(" ")
        "<apex:page #{params}>"
      end

      def end_page
        "</apex:page>"
      end

      def resource_url(file)
        resource, file = file.split('/', 2)
        "{!URLFOR($Resource.#{resource}, '/#{file}')}"
      end

      def stylesheet_include_tag(*files)
        each_resource_file(files, "css") do |file|
          %Q|<apex:stylesheet value="#{resource_url(file)}" />|
        end
      end

      def javascript_include_tag(*files)
        each_resource_file(files, "js") do |file|
          %Q|<script type="text/javascript" src="#{resource_url(file)}"></script>|
        end
      end

      def as_json_array(collection, var)
        <<-EOS.margin
          [<apex:repeat value="{!#{collection}}" var="#{var}" rows="1">
            #{send("#{var}_json")}
          </apex:repeat>
          <apex:repeat value="{!#{collection}}" var="#{var}" first="1">
            ,#{send("#{var}_json")}
          </apex:repeat>]
        EOS
      end

      def output_file
        "#{src}/pages/#{base}"
      end
    end

    class TestPage < Base
      def page(opts={})
        <<-EOS.margin
          <html>
            <head>
              <title>Test Page: #{opts[:controller]}</title>
            </head>
            <body>
        EOS
      end

      def end_page
        <<-EOS.margin
          </body>
          </html>
        EOS
      end

      def resource_url(file)
        "../resources/#{file}"
      end

      def stylesheet_include_tag(*files)
        each_resource_file(files, "css") do |file|
          %Q|<link rel="stylesheet" type="text/css" href="#{resource_url(file)}" />|
        end
      end

      def javascript_include_tag(*files)
        each_resource_file(files, "js") do |file|
          %Q|<script type="text/javascript" src="#{resource_url(file)}"></script>|
        end
      end

      def as_json_array(collection, var)
        send("#{var}_json")
      end

      def output_file
        "#{src}/pages-test/#{base}.html"
      end
    end
  end
end
