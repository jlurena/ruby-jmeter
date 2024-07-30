require 'csv'
require_relative "../helpers/running_statistics"

module RubyJmeter::Report
  class Summary

    attr_reader :avg,
      :error_percentage,
      :max,
      :min,
      :p10,
      :p50,
      :p95,
      :requests_per_minute,
      :response_codes,
      :standard_deviation,
      :total_bytes,
      :total_elapsed_time,
      :total_errors,
      :total_idle_time,
      :total_latency,
      :total_requests,
      :total_sent_bytes

    alias_method :rpm, :requests_per_minute
    alias_method :std, :standard_deviation
    alias_method :median, :p50

    def initialize(file_path)
      @running_statistics_helper = RubyJmeter::RunningStatistisc.new

      @max                    = 0
      @min                    = 1000000
      @response_codes         = Hash.new { |h, k| h[k.to_s] = 0 }
      @total_bytes            = 0
      @total_elapsed_time     = 0
      @total_errors           = 0
      @total_idle_time        = 0
      @total_latency          = 0
      @total_requests         = 0
      @total_sent_bytes       = 0

      load_data!(file_path)
    end

    private

    def load_data!(file_path)
      line_item = nil
      CSV.foreach(file_path, headers: true, header_converters: :symbol, converters: :numeric) do |row|
        line_item = row.to_hash

        elapsed = line_item.fetch(:elapsed)

        @running_statistics_helper.add_number(elapsed)

        @total_requests                                 += 1
        @total_elapsed_time                             += elapsed
        @response_codes[line_item.fetch(:responsecode)] += 1
        @total_errors                                   += (line_item.fetch(:success) == 'true') ? 0 : 1
        @total_bytes                                    += line_item.fetch(:bytes, 0)
        @total_sent_bytes                               += line_item.fetch(:sentbytes, 0)
        @total_latency                                  += line_item.fetch(:latency)
        @total_idle_time                                += line_item.fetch(:idletime)
        @min                                             = [@min, elapsed].min
        @max                                             = [@max, elapsed].max
      end

      @p10, @p50, @p95 = @running_statistics_helper.get_percentiles(0.1, 0.5, 0.95)
      @error_percentage    = (total_errors.to_f / total_requests) * 100
      @avg                 = @running_statistics_helper.avg
      @requests_per_minute = total_requests / (total_elapsed_time / 1000)
      @standard_deviation  = @running_statistics_helper.std
    end
  end
end
