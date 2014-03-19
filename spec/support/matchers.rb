RSpec::Matchers.define :map_specs do |specs|
  match do |autotest|
    @specs = specs
    @autotest = prepare(autotest)
    autotest.test_files_for(@file) == specs
  end

  chain :to do |file|
    @file = file
  end

  failure_message_for_should do
    "expected #{@autotest.class} to map #{@specs.inspect} to #{@file.inspect}\ngot #{@actual.inspect}"
  end

  def prepare(autotest)
    find_order = @specs.dup << @file
    autotest.instance_exec { @find_order = find_order }
    autotest
  end
end

RSpec::Matchers.define :fail_with do |exception_klass|
  match do |example|
    failure_reason(example, exception_klass).nil?
  end

  failure_message_for_should do |example|
    "expected example to fail with a #{exception_klass} exception, but #{failure_reason(example, exception_klass)}"
  end

  def failure_reason(example, exception_klass)
    result = example.metadata[:execution_result]
    case
      when example.metadata[:pending] then "was pending"
      when result.status != 'failed' then result.status
      when !result.exception.is_a?(exception_klass) then "failed with a #{result.exception.class}"
      else nil
    end
  end
end

RSpec::Matchers.define :pass do
  match do |example|
    failure_reason(example).nil?
  end

  failure_message_for_should do |example|
    "expected example to pass, but #{failure_reason(example)}"
  end

  def failure_reason(example)
    result = example.metadata[:execution_result]
    case
      when example.metadata[:pending] then "was pending"
      when result.status != 'passed' then result.status
      else nil
    end
  end
end

RSpec::Matchers.module_exec do
  alias_method :have_failed_with, :fail_with
  alias_method :have_passed, :pass
end

RSpec::Matchers.define :be_pending_with do |message|
  match do |example|
    example.pending? && example.execution_result.pending_message == message
  end

  failure_message_for_should do |example|
    "expected: example pending with #{message.inspect}\n     got: #{example.execution_result.pending_message.inspect}"
  end
end

RSpec::Matchers.define :be_skipped_with do |message|
  match do |example|
    example.skipped? && example.execution_result.pending_message == message
  end

  failure_message_for_should do |example|
    "expected: example skipped with #{message.inspect}\n     got: #{example.execution_result.pending_message.inspect}"
  end
end
