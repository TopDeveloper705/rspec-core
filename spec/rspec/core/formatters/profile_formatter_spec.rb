require 'spec_helper'
require 'rspec/core/formatters/profile_formatter'

RSpec.describe RSpec::Core::Formatters::ProfileFormatter do
  include FormatterSupport

  def profile *groups
    groups.each { |group| group.run(reporter) }
    examples = groups.map(&:examples).flatten
    total_time = examples.map { |e| e.execution_result.run_time }.inject(&:+)
    send_notification :dump_profile, profile_notification(total_time, examples, 10)
  end

  describe "#dump_profile", :slow do
    example_line_number = nil

    shared_examples_for "profiles examples" do
      it "names the example" do
        expect(output.string).to match(/group example/m)
      end

      it "prints the time" do
        expect(output.string).to match(/0(\.\d+)? seconds/)
      end

      it "prints the path" do
        filename = __FILE__.split(File::SEPARATOR).last
        expect(output.string).to match(/#{filename}\:#{example_line_number}/)
      end

      it "prints the percentage taken from the total runtime" do
        expect(output.string).to match(/, 100.0% of total time\):/)
      end

      it "doesn't profile a single example group" do
        expect(output.string).not_to match(/slowest example groups/)
      end
    end

    context "with one example group" do
      before do
        example_clock = class_double(RSpec::Core::Time, :now => RSpec::Core::Time.now + 0.5)

        profile(RSpec::Core::ExampleGroup.describe("group") do
          example("example") do |example|
            # make it look slow without actually taking up precious time
            example.clock = example_clock
          end
          example_line_number = __LINE__ - 4
        end)
      end

      it_should_behave_like "profiles examples"
    end

    context "with multiple example groups" do
      before do
        example_clock = class_double(RSpec::Core::Time, :now => RSpec::Core::Time.now + 0.5)

        group1 = RSpec::Core::ExampleGroup.describe("slow group") do
          example("example") do |example|
            # make it look slow without actually taking up precious time
            example.clock = example_clock
          end
            example_line_number = __LINE__ - 4
        end
        group2 = RSpec::Core::ExampleGroup.describe("fast group") do
          example("example 1") { }
          example("example 2") { }
        end
        profile group1, group2
      end

      it "prints the slowest example groups" do
        expect(output.string).to match(/slowest example groups/)
      end

      it "prints the time" do
        expect(output.string).to match(/0(\.\d+)? seconds/)
      end

      it "ranks the example groups by average time" do
        expect(output.string).to match(/slow group(.*)fast group/m)
      end
    end

    it "depends on parent_groups to get the top level example group" do
      ex = nil
      group = RSpec::Core::ExampleGroup.describe
      group.describe("group 2") do
        describe "group 3" do
          ex = example("nested example 1")
        end
      end

      expect(ex.example_group.parent_groups.last).to eq(group)
    end
  end
end
