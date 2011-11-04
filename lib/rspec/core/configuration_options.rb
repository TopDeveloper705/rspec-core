require 'erb'

module RSpec
  module Core
    class ConfigurationOptions
      attr_reader :options

      def initialize(args)
        @args = args
      end

      def configure(config)
        formatters = options.delete(:formatters)

        if line_numbers = options.delete(:line_numbers)
          config.line_numbers = line_numbers
        end
        if full_description = options.delete(:full_description)
          config.full_description = full_description
        end

        order(options.keys, :libs, :requires, :default_path, :pattern).each do |key|
          # temp to get through refactoring - eventually all options will be
          # set using force
          if [:color, :inclusion_filter, :exclusion_filter].include? key
            config.force key => options[key]
          else
            config.send("#{key}=", options[key]) if config.respond_to?("#{key}=")
          end
        end

        formatters.each {|pair| config.add_formatter(*pair) } if formatters
      end

      def parse_options
        @options ||= (file_options << command_line_options << env_options).inject do |merged, pending|
          Configuration.reconcile_opposing_filters(merged, pending, :inclusion_filter, :exclusion_filter)
          Configuration.reconcile_opposing_filters(merged, pending, :exclusion_filter, :inclusion_filter)
          merged.merge(pending)
        end
      end

      def drb_argv
        DrbOptions.new(options).options
      end

    private

      def order(keys, *ordered)
        ordered.reverse.each do |key|
          keys.unshift(key) if keys.delete(key)
        end
        keys
      end

      def file_options
        custom_options_file ? [custom_options] : [global_options, local_options]
      end

      def env_options
        ENV["SPEC_OPTS"] ? Parser.parse!(ENV["SPEC_OPTS"].split) : {}
      end

      def command_line_options
        @command_line_options ||= Parser.parse!(@args).merge :files_or_directories_to_run => @args
      end

      def custom_options
        options_from(custom_options_file)
      end

      def local_options
        @local_options ||= options_from(local_options_file)
      end

      def global_options
        @global_options ||= options_from(global_options_file)
      end

      def options_from(path)
        Parser.parse(args_from_options_file(path))
      end

      def args_from_options_file(path)
        return [] unless path && File.exist?(path)
        config_string = options_file_as_erb_string(path)
        config_string.split(/\n+/).map {|l| l.split}.flatten
      end

      def options_file_as_erb_string(path)
        ERB.new(File.read(path)).result(binding)
      end

      def custom_options_file
        command_line_options[:custom_options_file]
      end

      def local_options_file
        ".rspec"
      end

      def global_options_file
        begin
          File.join(File.expand_path("~"), ".rspec")
        rescue ArgumentError
          warn "Unable to find ~/.rspec because the HOME environment variable is not set"
          nil
        end
      end
    end
  end
end
