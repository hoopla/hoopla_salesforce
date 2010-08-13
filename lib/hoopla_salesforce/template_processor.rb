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
    end

    class VisualForce < Base
      def as_json_array(collection, var)
        <<-EOS.margin
          <apex:repeat value="{!#{collection}}" var="#{var}" rows="1">
            #{send("#{var}_json")}
          </apex:repeat>
          <apex:repeat value="{!#{collection}}" var="#{var}" first="1">
            ,#{send("#{var}_json")}
          </apex:repeat>
        EOS
      end

      def output_file
        "#{src}/pages/#{base}"
      end
    end

    class TestPage < Base
      def output_file
        "#{src}/pages-test/#{base}.html"
      end
    end

    def initialize(src, file)
      VisualForce.new(src, file)
      #TestPage.new(src, file)
    end
  end
end
