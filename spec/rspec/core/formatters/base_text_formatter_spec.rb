require 'spec_helper'
require 'rspec/core/formatters/base_text_formatter'

describe RSpec::Core::Formatters::BaseTextFormatter do
  let(:output) { StringIO.new }
  let(:formatter) { RSpec::Core::Formatters::BaseTextFormatter.new(output) }

  describe "#summary_line" do
    it "with 0s outputs pluralized (excluding pending)" do
      formatter.summary_line(0,0,0).should eq("0 examples, 0 failures")
    end

    it "with 1s outputs singular (including pending)" do
      formatter.summary_line(1,1,1).should eq("1 example, 1 failure, 1 pending")
    end

    it "with 2s outputs pluralized (including pending)" do
      formatter.summary_line(2,2,2).should eq("2 examples, 2 failures, 2 pending")
    end
  end

  describe "#dump_commands_to_rerun_failed_examples" do
    it "includes command to re-run each failed example" do
      group = RSpec::Core::ExampleGroup.describe("example group") do
        it("fails") { fail }
      end
      line = __LINE__ - 2
      group.run(formatter)
      formatter.dump_commands_to_rerun_failed_examples
      output.string.should include("rspec #{RSpec::Core::Metadata::relative_path("#{__FILE__}:#{line}")} # example group fails")
    end
  end

  describe "#dump_failures" do
    let(:group) { RSpec::Core::ExampleGroup.describe("group name") }

    before { RSpec.configuration.stub(:color_enabled?) { false } }

    def run_all_and_dump_failures
      group.run(formatter)
      formatter.dump_failures
    end

    it "preserves formatting" do
      group.example("example name") { "this".should eq("that") }

      run_all_and_dump_failures

      output.string.should =~ /group name example name/m
      output.string.should =~ /(\s+)expected: \"that\"\n\1     got: \"this\"/m
    end

    context "with an exception without a message" do
      it "does not throw NoMethodError" do
        exception_without_message = Exception.new()
        exception_without_message.stub(:message) { nil }
        group.example("example name") { raise exception_without_message }
        expect { run_all_and_dump_failures }.not_to raise_error(NoMethodError)
      end

      it "preserves ancestry" do
        example = group.example("example name") { raise "something" }
        run_all_and_dump_failures
        example.example_group.parent_groups.size.should == 1
      end
    end

    context "with an exception that has an exception instance as its message" do
      it "does not raise NoMethodError" do
        gonzo_exception = RuntimeError.new
        gonzo_exception.stub(:message) { gonzo_exception }
        group.example("example name") { raise gonzo_exception }
        expect { run_all_and_dump_failures }.not_to raise_error(NoMethodError)
      end
    end

    context "with an instance of an anonymous exception class" do
      it "substitutes '(anonymous error class)' for the missing class name" do
        exception = Class.new(StandardError).new
        group.example("example name") { raise exception }
        run_all_and_dump_failures
        output.string.should include('(anonymous error class)')
      end
    end

    context "with an exception class other than RSpec" do
      it "does not show the error class" do
        group.example("example name") { raise NameError.new('foo') }
        run_all_and_dump_failures
        output.string.should =~ /NameError/m
      end
    end

    context "with a failed expectation (rspec-expectations)" do
      it "does not show the error class" do
        group.example("example name") { "this".should eq("that") }
        run_all_and_dump_failures
        output.string.should_not =~ /RSpec/m
      end
    end

    context "with a failed message expectation (rspec-mocks)" do
      it "does not show the error class" do
        group.example("example name") { "this".should_receive("that") }
        run_all_and_dump_failures
        output.string.should_not =~ /RSpec/m
      end
    end

    context 'for #share_examples_for' do
      it 'outputs the name and location' do

        share_examples_for 'foo bar' do
          it("example name") { "this".should eq("that") }
        end

        line = __LINE__.next
        group.it_should_behave_like('foo bar')

        run_all_and_dump_failures

        output.string.should include(
          'Shared Example Group: "foo bar" called from ' +
            "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
        )
      end

      context 'that contains nested example groups' do
        it 'outputs the name and location' do
          share_examples_for 'foo bar' do
            describe 'nested group' do
              it("example name") { "this".should eq("that") }
            end
          end

          line = __LINE__.next
          group.it_should_behave_like('foo bar')

          run_all_and_dump_failures

          output.string.should include(
            'Shared Example Group: "foo bar" called from ' +
              "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
          )
        end
      end
    end

    context 'for #share_as' do
      before { RSpec.stub(:warn) }

      it 'outputs the name and location' do

        share_as :FooBar do
          it("example name") { "this".should eq("that") }
        end

        line = __LINE__.next
        group.send(:include, FooBar)

        run_all_and_dump_failures

        output.string.should include(
          'Shared Example Group: "FooBar" called from ' +
            "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
        )
      end

      context 'that contains nested example groups' do
        it 'outputs the name and location' do

          share_as :NestedFoo do
            describe 'nested group' do
              describe 'hell' do
                it("example name") { "this".should eq("that") }
              end
            end
          end

          line = __LINE__.next
          group.send(:include, NestedFoo)

          run_all_and_dump_failures

          output.string.should include(
            'Shared Example Group: "NestedFoo" called from ' +
              "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
          )
        end
      end
    end
  end

  describe "#dump_pending" do
    let(:group) { RSpec::Core::ExampleGroup.describe("group name") }

    before { RSpec.configuration.stub(:color_enabled?) { false } }

    def run_all_and_dump_pending
      group.run(formatter)
      formatter.dump_pending
    end

    context "with show_failures_in_pending_blocks setting enabled" do
      before { RSpec.configuration.stub(:show_failures_in_pending_blocks?) { true } }

      it "preserves formatting" do
        group.example("example name") { pending { "this".should eq("that") } }

        run_all_and_dump_pending

        output.string.should =~ /group name example name/m
        output.string.should =~ /(\s+)expected: \"that\"\n\1     got: \"this\"/m
      end

      context "with an exception without a message" do
        it "does not throw NoMethodError" do
          exception_without_message = Exception.new()
          exception_without_message.stub(:message) { nil }
          group.example("example name") { pending { raise exception_without_message } }
          expect { run_all_and_dump_pending }.not_to raise_error(NoMethodError)
        end
      end

      context "with an exception class other than RSpec" do
        it "does not show the error class" do
          group.example("example name") { pending { raise NameError.new('foo') } }
          run_all_and_dump_pending
          output.string.should =~ /NameError/m
        end
      end

      context "with a failed expectation (rspec-expectations)" do
        it "does not show the error class" do
          group.example("example name") { pending { "this".should eq("that") } }
          run_all_and_dump_pending
          output.string.should_not =~ /RSpec/m
        end
      end

      context "with a failed message expectation (rspec-mocks)" do
        it "does not show the error class" do
          group.example("example name") { pending { "this".should_receive("that") } }
          run_all_and_dump_pending
          output.string.should_not =~ /RSpec/m
        end
      end

      context 'for #share_examples_for' do
        it 'outputs the name and location' do

          share_examples_for 'foo bar' do
            it("example name") { pending { "this".should eq("that") } }
          end

          line = __LINE__.next
          group.it_should_behave_like('foo bar')

          run_all_and_dump_pending

          output.string.should include(
            'Shared Example Group: "foo bar" called from ' +
            "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
          )
        end

        context 'that contains nested example groups' do
          it 'outputs the name and location' do
            share_examples_for 'foo bar' do
              describe 'nested group' do
                it("example name") { pending { "this".should eq("that") } }
              end
            end

            line = __LINE__.next
            group.it_should_behave_like('foo bar')

            run_all_and_dump_pending

            output.string.should include(
              'Shared Example Group: "foo bar" called from ' +
              "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
            )
          end
        end
      end

      context 'for #share_as' do
        before { RSpec.stub(:warn) }

        it 'outputs the name and location' do

          share_as :FooBar2 do
            it("example name") { pending { "this".should eq("that") } }
          end

          line = __LINE__.next
          group.send(:include, FooBar2)

          run_all_and_dump_pending

          output.string.should include(
            'Shared Example Group: "FooBar2" called from ' +
            "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
          )
        end

        context 'that contains nested example groups' do
          it 'outputs the name and location' do

            share_as :NestedFoo2 do
              describe 'nested group' do
                describe 'hell' do
                  it("example name") { pending { "this".should eq("that") } }
                end
              end
            end

            line = __LINE__.next
            group.send(:include, NestedFoo2)

            run_all_and_dump_pending

            output.string.should include(
              'Shared Example Group: "NestedFoo2" called from ' +
              "./spec/rspec/core/formatters/base_text_formatter_spec.rb:#{line}"
            )
          end
        end
      end
    end

    context "with show_failures_in_pending_blocks setting disabled" do
      before { RSpec.configuration.stub(:show_failures_in_pending_blocks?) { false } }

      it "does not output the failure information" do
        group.example("example name") { pending { "this".should eq("that") } }
        run_all_and_dump_pending
        output.string.should_not =~ /(\s+)expected: \"that\"\n\1     got: \"this\"/m
      end
    end
  end

  describe "#dump_profile" do
    example_line_number = nil

    before do
      group = RSpec::Core::ExampleGroup.describe("group") do
        # Use a sleep so there is some measurable time, to ensure
        # the reported percent is 100%, not 0%.
        example("example") { sleep 0.001 }
        example_line_number = __LINE__ - 1
      end
      group.run(double('reporter').as_null_object)

      formatter.stub(:examples) { group.examples }
      RSpec.configuration.stub(:profile_examples) { 10 }
    end

    it "names the example" do
      formatter.dump_profile
      output.string.should =~ /group example/m
    end

    it "prints the time" do
      formatter.dump_profile
      output.string.should =~ /0(\.\d+)? seconds/
    end

    it "prints the path" do
      formatter.dump_profile
      filename = __FILE__.split(File::SEPARATOR).last

      output.string.should =~ /#{filename}\:#{example_line_number}/
    end

    it "prints the percentage taken from the total runtime" do
      formatter.dump_profile
      output.string.should =~ /, 100.0% of total time\):/
    end
  end

  describe "custom_colors" do
    it "uses the custom success color" do
      RSpec.configure do |config|
        config.color_enabled = true
        config.tty = true
        config.success_color = :cyan
      end
      formatter.dump_summary(0,1,0,0)
      output.string.should include("\e[36m")
    end
  end

  describe "#colorize" do
    it "accepts a VT100 integer code and formats the text with it" do
       formatter.colorize('abc', 32).should == "\e[32mabc\e[0m"
    end

    it "accepts a symbol as a color parameter and translates it to the correct integer code, then formats the text with it" do
       formatter.colorize('abc', :green).should == "\e[32mabc\e[0m"
    end

    it "accepts a non-default color symbol as a parameter and translates it to the correct integer code, then formats the text with it" do
       formatter.colorize('abc', :cyan).should == "\e[36mabc\e[0m"
    end
  end

end
