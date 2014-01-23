require 'spec_helper'
require 'support/in_sub_process'

main = self

RSpec.describe "The RSpec DSL" do
  include InSubProcess

  shared_examples_for "a dsl method" do |*method_names|
    context "when expose_dsl_globally is enabled" do
      def enable
        in_sub_process do
          changing_expose_dsl_globally do
            RSpec.configuration.expose_dsl_globally = true
          end

          yield
        end
      end

      it 'are only available off of `RSpec`, `main` and modules' do
        enable do
          expect(::RSpec).to respond_to(*method_names)
          expect(main).to respond_to(*method_names)
          expect(Module.new).to respond_to(*method_names)

          expect(Object.new).not_to respond_to(*method_names)
        end
      end
    end

    context "when expose_dsl_globally is disabled" do
      def disable
        in_sub_process do
          changing_expose_dsl_globally do
            RSpec.configuration.expose_dsl_globally = false
          end

          yield
        end
      end

      it 'are only available off of `RSpec`' do
        disable do
          expect(::RSpec).to respond_to(*method_names)

          expect(main).not_to respond_to(*method_names)
          expect(Module.new).not_to respond_to(*method_names)
          expect(Object.new).not_to respond_to(*method_names)
        end
      end
    end
  end

  describe "built in DSL methods" do
    include_examples "a dsl method",
      :example_group, :describe, :context,
      :share_examples_for, :shared_examples_for, :shared_examples, :shared_context do

      def changing_expose_dsl_globally
        yield
      end
    end
  end

  describe "custom example group aliases" do
    context "when adding aliases before exposing the DSL globally" do
      include_examples "a dsl method", :detail do
        def changing_expose_dsl_globally
          RSpec.configuration.alias_example_group_to(:detail)
          yield
        end
      end
    end

    context "when adding aliases after exposing the DSL globally" do
      include_examples "a dsl method", :detail do
        def changing_expose_dsl_globally
          yield
          RSpec.configuration.alias_example_group_to(:detail)
        end
      end
    end
  end
end

