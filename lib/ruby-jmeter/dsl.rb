module RubyJmeter
  class ExtendedDSL < DSL
    include Parser
    attr_accessor :root

    def initialize(params = {})
      @root = Nokogiri::XML(<<-EOF.strip_heredoc)
        <?xml version="1.0" encoding="UTF-8"?>
        <jmeterTestPlan version="1.2" properties="3.1" jmeter="3.1" ruby-jmeter="3.0">
        <hashTree>
        </hashTree>
        </jmeterTestPlan>
      EOF
      node = RubyJmeter::TestPlan.new(params)

      @current_node = @root.at_xpath('//jmeterTestPlan/hashTree')
      @current_node = attach_to_last(node)
    end

    def out(params = {})
      puts doc.to_xml(indent: 2)
    end

    def jmx(params = {})
      file(params)
      logger.info "Test plan saved to: #{params[:file]}"
    end

    def to_xml
      doc.to_xml(indent: 2)
    end

    def to_doc
      doc.clone
    end

    def run(params = {})
      file(params)
      logger.warn 'Test executing locally ...'

      jmeter_path = params[:path].nil? ? 'jmeter' : File.join(params[:path])
      log_file = params.fetch(:log, 'jmeter.log')
      jtl_file = params.fetch(:jtl, 'jmeter.jtl')
      properties = params[:properties].nil? ? "" : build_properties(params[:properties]) if params[:properties]

      cmd = "#{jmeter_path} -t #{params[:file]} -j #{log_file} -l #{jtl_file} #{properties}"
      logger.debug cmd if params[:debug]
      Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
        while line = stdout_err.gets
          logger.debug line.chomp if params[:debug]
        end

        exit_status = wait_thr.value
        abort "FAILED !!! #{cmd}" unless exit_status.success?
      end
      logger.info "Local Results at: #{jtl_file}"

      Report::Summary.new(jtl_file)
    end

    private

    def hash_tree
      Nokogiri::XML::Node.new("hashTree", @root)
    end

    def attach_to_last(node)
      ht = hash_tree
      last_node = @current_node
      last_node << node.doc.children << ht
      ht
    end

    def attach_node(node, &block)
      ht = attach_to_last(node)
      previous = @current_node
      @current_node = ht
      instance_exec(&block) if block
      @current_node = previous
    end

    def file(params = {})
      params[:file] ||= 'ruby-jmeter.jmx'
      File.open(params[:file], 'w') { |file| file.write(doc.to_xml(indent: 2)) }
    end

    def doc
      Nokogiri::XML(@root.to_s, &:noblanks)
    end

    def build_properties(properties)
      if properties.kind_of?(String)
        "-q #{properties}"
      elsif properties.kind_of?(Hash)
        properties.map{ |k,v| "-J#{k}=#{v}" }.join(" ")
      end
    end

    def logger
      @log ||= Logger.new(STDOUT)
      @log.level = Logger::DEBUG
      @log
    end
  end
end

def test(params = {}, &block)
  RubyJmeter.dsl_eval(RubyJmeter::ExtendedDSL.new(params), &block)
end
