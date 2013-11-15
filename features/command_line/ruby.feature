Feature: run with ruby command

  You can use the `ruby` command to run specs. You just need to require
  `rspec/autorun`.

  Generally speaking, you're better off using the `rspec` command, which
  avoids the complexity of `rspec/autorun` (e.g. no `at_exit` hook needed!),
  but some tools only work with the `ruby` command.

  Scenario: Require `rspec/autorun` from a spec file
    Given a file named "example_spec.rb" with:
      """ruby
      require 'rspec/autorun'

      describe 1 do
        it "is < 2" do
          expect(1).to be < 2
        end
      end
      """
    When I run `ruby example_spec.rb`
    Then the output should contain "1 example, 0 failures"

  Scenario: Use ruby's `-r` option to require `rspec/autorun`
    Given a file named "example_spec.rb" with:
      """ruby
      require 'rspec/core'

      describe 1 do
        it "is < 2" do
          expect(1).to be < 2
        end
      end
      """
    When I run `ruby -rrspec/autorun example_spec.rb`
    Then the output should contain "1 example, 0 failures"

