require 'erb'

module RubyJmeter::Report
  class Generator
    def initialize(comparator, reports, output_format = :html)
      @comparator = comparator
      @reports = reports
      @output_format = output_format
    end

    def generate_report(output_path)
      case @output_format
      when :html
        generate_html_report(output_path)
      else
        generate_text_report(output_path)
      end
    rescue => e
      puts "Error generating report: #{e.message}"
    end

    private

    def generate_html_report(output_path)
      template_path = File.join(__dir__, '..', 'views', 'report_template.html.erb')
      template = File.read(template_path)
      result = ERB.new(template).result(binding)
      File.write(output_path, result)
    end

    def generate_text_report(output_path)
      report_text = "Comparison Report\n\n"

      report_text << format_line(['Label', 'Requests', 'Errors', 'Error %', 'Min', 'Median', 'Avg', 'Max', 'Std', 'P10', 'P50', 'P95'])
      report_text << '-' * 90 + "\n"

      @reports.each_with_index do |report, index|
        report_text << format_line([
          index == 0 ? "Base Metric" : "Test Metric",
          report.total_requests,
          report.total_errors,
          sprintf('%.2f', report.error_percentage),
          report.min,
          report.median,
          sprintf('%.2f', report.avg),
          report.max,
          sprintf('%.2f', report.std),
          sprintf('%.2f', report.p10),
          sprintf('%.2f', report.p50),
          sprintf('%.2f', report.p95)
        ])
      end

      File.write(output_path, report_text)
    end

    def format_line(values)
      values.map { |v| v.to_s.ljust(10) }.join(' ') + "\n"
    end
  end
end
