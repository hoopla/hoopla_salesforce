require 'pp'

module HooplaSalesforce
  class TextReporter
    attr_reader :result

    def initialize(result)
      @result = result
    end

    def green
      "\e[32m"
    end

    def red
      "\e[31m"
    end

    def end_color
      "\e[0m"
    end

    def report
      indent            = "  "
      updated_files     = []
      problems          = []
      test_failures     = []
      coverage_warnings = []

      result[:messages].each do |message|
        if message[:success]
          status = " "
          status = "U" if message[:changed]
          status = "D" if message[:deleted]
          status = "A" if message[:created]

          updated_files << "#{green}#{indent}#{status} #{message[:file_name]}#{end_color}"
        end 

        if message[:problem]
          problem = "#{red}#{indent}#{message[:file_name]}:#{message[:line_number]} (column #{message[:column_number]})\n" 
          problem += "#{indent*2}#{message[:problem]}#{end_color}"
          problems << problem
        end
      end

      if ENV['FULL_OUTPUT']
        pp result
      else
        puts "(Run with FULL_OUTPUT=true to show full deploy output)"
      end

      puts
      puts "Updated files:"
      puts updated_files.join("\n")
      puts

      puts "Test results:"
      test_result = result[:run_test_result]
      failures    = test_result[:num_failures].to_i
      passes      = test_result[:num_tests_run].to_i - failures
      print "#{indent}Passes: #{green}#{passes}#{end_color} "
      print "Failures: #{red}#{failures}#{end_color} "
      puts  "Duration: #{test_result[:total_time]} ms"
      puts

      # :failures is only an array if we have more than 1. Fun...
      [test_result[:failures]].compact.flatten.each do |failure|
        message = "#{indent}#{red}#{failure[:name]}.#{failure[:method_name]}: #{failure[:message]}\n"
        message += failure[:stack_trace].split("\n").map{ |l| indent * 2 + l }.join("\n")
        message += end_color
        test_failures << message
      end

      if !test_failures.empty?
        puts "Test failures:"
        puts test_failures.join("\n")
        puts
      end

      (test_result[:code_coverage_warnings] || []).each do |warning|
        coverage_warnings << "#{indent}#{warning[:name]}: #{warning[:message]}"
      end
      
      if !coverage_warnings.empty?
        puts "Coverage warnings:"
        puts coverage_warnings.join("\n")
        puts
      end

      if !problems.empty?
        puts "Problems:"
        puts problems.join("\n")
        puts
      end

      return problems.empty?
    end
  end
end

