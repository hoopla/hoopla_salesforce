module HooplaSalesforce
  module Utils
    def extract_class_name(body)
      (match = body.match(/\bclass\s+(\w+)\s*\{\s*/)) && match[1]
    end

    def extract_trigger_name(body)
      (match = body.match(/\btrigger\s+(\w+)\s/)) && match[1]
    end
  end
end
