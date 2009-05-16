require 'cucumber/formatter/console'

# Cucumber formatter which displays nothing while the process is running,
# but rather pumps out details on each Scenario at the end in such a way as
# to make it simple to parse for updating a CI system or task list.
module Cucumber
  module Formatter
    class Stats < Ast::Visitor
      include Console

      def initialize(step_mother, io, options)
        super(step_mother)
        @io = io
        @options = options
        @status={}
      end

      def visit_features(features)
        super
        print_summary
      end

      def visit_multiline_arg(multiline_arg)
        @multiline_arg = true
        super
        @multiline_arg = false
      end

      def visit_step_name(keyword, step_match, status, source_indent, background)
        @status[@current_feature] ||= {}
        @status[@current_feature][@current_scenario] ||= { :passed => 0, :failed => 0, :pending => 0, :undefined => 0, :skipped => 0, :total => 0 }
        @status[@current_feature][@current_scenario][status] += 1
        @status[@current_feature][@current_scenario][:total] += 1
        return
      end

      def visit_feature_name(name)
        @current_feature=name.split(/\r\n|\r|\n/).first.gsub(/Feature:\s+/,'')
      end

      def visit_scenario_name(keyword, name, file_colon_line, source_indent)
        @current_scenario=name
      end

      private

      def print_summary
        @status.each do |feature, feature_data|
          feature_data.each do |scenario, data|
            total = data[:total]
            passed = data[:passed]
            failed = data[:failed] + data[:undefined] + data[:skipped] + data[:pending]
            stats=[]
            stats << "#{passed} passed" if passed > 0
            stats << "#{failed} failed" if failed > 0
            stats.unshift("#{total} steps") if stats.size > 1
            @io.print "#{feature} :: #{scenario} (#{stats.join(', ')})\n"
          end
        end
      end

    end
  end
end
