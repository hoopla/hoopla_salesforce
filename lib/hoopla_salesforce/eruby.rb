require 'erubis'

module HooplaSalesforce
  class OutputBuffer < String
    alias :append=           :<<
    alias :safe_concat       :<<
  end

  module CaptureHelper
    def capture
      @output_buffer, original_buffer = HooplaSalesforce::OutputBuffer.new, @output_buffer
      yield
      @output_buffer, buffer = original_buffer, @output_buffer
      buffer
    end
  end

  class Eruby < Erubis::Eruby
    def add_preamble(src)
      src << "@output_buffer = HooplaSalesforce::OutputBuffer.new;"
    end

    def add_text(src, text)
      return if text.empty?
      src << "@output_buffer.safe_concat('" << escape_text(text) << "');"
    end

    BLOCK_EXPR = /\s+(do|\{)(\s*\|[^|]*\|)?\s*\Z/

    def add_expr_literal(src, code)
      if code =~ BLOCK_EXPR
        src << '@output_buffer.append= ' << code
      else
        src << '@output_buffer.append= (' << code << ');'
      end
    end

    def add_stmt(src, code)
      if code =~ BLOCK_EXPR
        src << code
      else
        super
      end
    end

    def add_expr_escaped(src, code)
      src << '@output_buffer.append= ' << escaped_expr(code) << ';'
    end

    def add_postamble(src)
      src << '@output_buffer.to_s'
    end
  end
end
