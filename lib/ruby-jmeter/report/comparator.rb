module RubyJmeter::Report
  class Comparator
    attr_reader :cohens_d, :t_statistic, :human_rating

    def initialize(base_report, test_report)
      @base_report = base_report
      @test_report = test_report
      compare_reports!
    end

    def pass?(cohens_d_limit = 0, raise_error = false)
      passes = cohens_d <= cohens_d_limit
      if !passes && raise_error
        raise "Failed Cohen's D. Expected:#{cohens_d_limit}, Actual:#{cohens_d}"
      end
      passes
    end

    private

    def compare_reports!
      @cohens_d =  calc_cohens_d(@base_report.avg, @test_report.avg, @base_report.std, @test_report.std).round(2)
      @t_statistic = calc_t_statistic(
        @base_report.avg,
        @test_report.avg,
        @base_report.std,
        @test_report.std,
        @test_report.total_requests
      ).round(2)

      set_diff_rating
    end

    def calc_cohens_d(mean1, mean2, sd1, sd2)
      mean_diff = mean1 - mean2
      pooled_sd = Math.sqrt((sd1**2 + sd2**2) / 2.0)
      mean_diff / pooled_sd
    end

    def calc_t_statistic(mean1, mean2, sd1, sd2, n2)
      numerator = mean1 - mean2
      denominator = Math.sqrt((sd1**2 + sd2**2) / n2)
      numerator / denominator
    end

    def set_diff_rating
      # 1. Get direction of movement
      s_dir = ""
      s_dir = "decrease" if cohens_d < 0
      s_dir = "increase" if cohens_d > 0

      # 2. Get magnitude of movement according to Sawilowsky's rule of thumb
      s_mag = case cohens_d.abs
              when 1.20...2.0 then "Very large"
              when 0.80...1.20 then "Large"
              when 0.50...0.80 then "Medium"
              when 0.02...0.50 then "Small"
              when 0.01...0.02 then "Very small"
              when 0.0...0.01 then "Negligible"
              else "Huge"
              end

      @human_rating = "#{s_mag} #{s_dir}"
    end
  end
end
