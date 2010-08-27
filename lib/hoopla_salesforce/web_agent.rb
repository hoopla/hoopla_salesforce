require 'mechanize'
require 'cgi'

module HooplaSalesforce
  class WebAgent
    LOGIN_URL   = 'https://login.salesforce.com'
    MAX_CLASSES = 10_000

    attr_reader :username, :password, :agent

    def initialize(username, password)
      @username = username
      @password = password
      @agent = Mechanize.new
      login
    end

    def login
      agent.get(LOGIN_URL).form_with(:name => 'login') do |login|
        login.un = username
        login.pw = password
      end.submit
    end

    def test_run_url(test, namespace)
      "/setup/build/runApexTest.apexp?class_id=#{test[:id]}&class_name=#{test[:name]}&ns_prefix=#{namespace}"
    end

    def test_results_dir
      "test-results"
    end

    def test_results_file(test_name)
      "#{test_results_dir}/#{test_name}.html"
    end

    def get_all_test_links
      page = agent.get('/01p')

      if page.search('.next') 
        expand_link = page.search('.fewerMore a').first['href']
        enough_rows = expand_link.sub(/rowsperpage=\d+/, "rowsperpage=#{MAX_CLASSES}")
        page = agent.get(enough_rows)
      end

      page.search('.dataCell[scope="row"] a')
    end

    # Runs the given tests from the Web UI
    # namespace is the package namespace without the __
    def run_tests(test_names, namespace = '')
      test_links = get_all_test_links

      tests = test_names.map do |test_name|
        { :id   => test_links.detect{ |a| a.text == test_name }['href'][1..-1],
          :name => test_name }
      end

      mkdir_p test_results_dir
      tests.each do |test|
        results_page = agent.get(test_run_url(test, namespace))
        results_table = results_page.search('.outer table td').first
        File.open(test_results_file(test[:name]), 'w') do |f|
          f.print results_table.inner_html
        end
    
        puts "#{test[:name]} complete, results in #{test_results_file(test[:name])}."
      end
    end
  end
end
