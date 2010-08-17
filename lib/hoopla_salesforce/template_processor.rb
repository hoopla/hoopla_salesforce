require 'erubis'

module HooplaSalesforce
  class TemplateProcessor
    class Base
      attr_reader :src, :base
      def initialize(src, file)
        @src     = src
        @base    = File.basename(file, '.erb')
        template = Erubis::Eruby.new(File.read(file))

        File.open(output_file, 'w') do |f|
          f.print template.result(binding)
        end
      end

      def each_resource_file(files, extension)
        files.map do |file|
          resource, file = file.split('/', 2)
          file += ".#{extension}" unless extension =~ /\.#{extension}$/
          yield resource, file
        end.join("\n")
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

      def stylesheet_include_tag(*files)
        each_resource_file(files, "css") do |resource, file|
          %Q|<apex:stylesheet value="{!URLFOR($Resource.#{resource}, '/#{file}')}" />|
        end
      end

      def javascript_include_tag(*files)
        each_resource_file(files, "js") do |resource, file|
          %Q|<script type="text/javascript" src="{!URLFOR($Resource.#{resource}, '/#{file}')}"></script>|
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

      def stylesheet_include_tag(*files)
        each_resource_file(files, "css") do |resource, file|
          %Q|<link rel="stylesheet" type="text/css" href="../resources/#{resource}/#{file}" />|
        end
      end

      def javascript_include_tag(*files)
        each_resource_file(files, "js") do |resource, file|
          %Q|<script type="text/javascript" src="../resources/#{resource}/#{file}"></script>|
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
