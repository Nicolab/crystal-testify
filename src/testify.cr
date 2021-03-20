# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

# Testing utilities for Crystal lang specs.
#
# Based on std's [Crystal Spec](https://crystal-lang.org/reference/guides/testing.html),
# Testify is an OOP abstraction for creating unit and integration tests.
# This allows structuring some tests in an objective of maintenability, extendability and reusability.
#
# > See [README](https://github.com/Nicolab/crystal-testify/) for more details and examples.
module Testify
  # Runs all tests of the classes inherited from `Testify::Test` class.
  #
  # Is equivalent to manually calling `.run` on each `Test` class.
  def self.run_all : Hash(String, Test)
    all = Hash(String, Test).new

    {% for tests_class in Test.all_subclasses.reject &.abstract? %}
      fail %("{{tests_class}}" already mounted) if all[{{tests_class.stringify}}]?
      all[{{tests_class.stringify}}] = {{tests_class.id}}.run
    {% end %}

    all
  end

  # Test class is equivalent of `describe` block (internally it's a mapping).
  # It is an alternative DSL ([Spec](https://crystal-lang.org/api/Spec.html) compliant)
  # for creating unit and integration tests.
  #
  # Any tests defined within a parent class will run for each child test case (by inheritance).
  # Macros, `abstract def`, `super` and other OOP features can be used as well to reduce duplication.
  #
  # Some additional features are also built in, such as the `Data` annotation and `Tracker` module.
  #
  # > See [README](https://github.com/Nicolab/crystal-testify/) for more details and examples.
  abstract class Test
    # This class is a refactoring (redesigned, corrected and improved) started from:
    # https://github.com/athena-framework/spec/blob/a28a66ee0985d5aed7948183a5942c1c04848a31/src/test_case.cr

    # `Tags` can be used to group tests and specs,
    # allowing to only run a subset of tests and/or specs when providing a `--tag` argument to the spec runner.
    #
    # Can be tagged:
    #
    # * classes inherited from the `Test` class (equivalent of `describe` block);
    # * and all `test_` methods (equivalent of `it` block);
    # * and of course the blocks (with the `tags` argument): `describe`, `context` and `it`.
    #
    # > See [Tagging Specs](https://crystal-lang.org/reference/guides/testing.html#tagging-specs) in the stdlib.
    annotation Tags; end

    # Focuses a specific test case.
    # Only focused `Test` class(es) or `test_` method(s) will be executed.
    #
    # > See [Focusing Specs](https://crystal-lang.org/reference/guides/testing.html#focusing-on-a-group-of-specs)
    # in the stdlib.
    annotation Focus; end

    # Defines a specific test case as `pending`.
    # A `Test` class or `test_` method marked as `Pending` is never evaluated.
    # It can be used to describe behaviour that is not yet implemented.
    #
    # > See [#pending](https://crystal-lang.org/api/master/Spec/Methods.html#pending%28description=%22assert%22,file=
    # __FILE__,line=__LINE__,end_line=__END_LINE__,focus:Bool=false,tags:String%7CEnumerable%28String%29%7CNil=nil,
    # &%29-instance-method) method.
    annotation Pending; end

    # Same as `Pending` (alias).
    alias Skip = Pending

    # Provides the data source to a specific test case (`test_` method).
    #
    # Example:
    #
    # ```
    # class UserTest < Testify::Test
    #   @[Data("get_model_values")]
    #   def test_create(values, expected)
    #     user = User.create(values)
    #     user.should be_a User
    #     user.to_h should eq expected
    #   end
    #
    #   # `Data` source.
    #   def get_model_values : Hash
    #     {
    #       "username" => "foo",
    #       "email"    => "hello@example.org",
    #       # ...
    #     }
    #   end
    # end
    # ```
    # > See [data-driven testing](https://en.wikipedia.org/wiki/Data-driven_testing).
    annotation Data; end

    # Runs the tests contained in the current `Test` class.
    #
    # > See `Testify.run_all` to run all tests contained in all the `Test` classes.
    def self.run
      instance = {{@type}}.new

      {% begin %}
        {% test_meth_reg = /^(?:f|p)?test_/ %}
        {{ (!!@type.annotation(Pending) || !!@type.annotation(Skip)) ? "pending".id : "describe".id }}(
          {{@type.name.stringify}},
          focus: {{!!@type.annotation Focus}}
          {% if (tags = @type.annotation(Tags)) %}, tags: {{tags.args}}{% end %}
        ) do
          before_all do
            instance.before_all
          end

          before_each do
            instance.before_each
          end

          after_all do
            instance.after_all
          end

          after_each do
            instance.after_each
          end

          around_all do |procsy|
            instance.around_all procsy
          end

          around_each do |procsy|
            instance.around_each procsy
          end

          {% methods = [] of Nil %}

          {% for parent in @type.ancestors.select &.<(Testify::Test) %}
            {% for method in parent.methods.select &.name.=~ test_meth_reg %}
              {% methods << method %}
            {% end %}
          {% end %}

          {% for test in methods + @type.methods.select &.name.=~ test_meth_reg %}
            {% focus = test.name.starts_with?("ftest_") || !!test.annotation Focus %}
            {% tags = (tags = test.annotation(Tags)) ? tags.args : nil %}
            {%
              spec_method = (
                test.name.starts_with?("ptest_") || !!test.annotation(Pending) || !!test.annotation(Skip)
              ) ? "pending" : "it"
            %}
            {% description = test.name.stringify.gsub(test_meth_reg, "").underscore.gsub(/_/, " ") %}

            {% if test.annotations(Data).empty? %}
              {{spec_method.id}}(
                {{description}},
                file: {{test.filename}},
                line: {{test.line_number}},
                end_line: {{test.end_line_number}},
                focus: {{focus}},
                tags: {{tags}}
              ) do
                instance.{{test.name.id}}
              end
            {% else %}
              {% for data_source in test.annotations Data %}
                {%
                  data_method_name = data_source[0] || data_source.raise(%(
                    One or more annotations "Data" for test "#{@type}##{test.name.id}" \
                    does not have its data source provided as argument.
                  ))
                %}

                {% methods = @type.methods %}

                {% for ancestor in @type.ancestors.select &.<=(Testify::Test) %}
                  {% methods += ancestor.methods %}
                {% end %}

                {%
                  data_method_return_type = (methods.find(&.name.stringify.==(data_method_name)).return_type || raise(
                    %(Data source "#{@type}##{data_method_name.id}" must return a Hash, NamedTuple, Array, or Tuple.)
                  )).resolve
                %}

                {% if data_method_return_type == Hash || data_method_return_type == NamedTuple %}
                  instance.{{data_method_name.id}}.each do |name, args|
                    {{spec_method.id}}(
                      "#{{{description}}} #{name}",
                      file: {{test.filename}},
                      line: {{test.line_number}},
                      end_line: {{test.end_line_number}},
                      focus: {{focus}},
                      tags: {{tags}}
                    ) do
                      instance.{{test.name.id}} *args
                    end
                  end
                {% elsif data_method_return_type == Array || data_method_return_type == Tuple %}
                  instance.{{data_method_name.id}}.each_with_index do |args, idx|
                    {{spec_method.id}}(
                      "#{{{description}}} #{idx}",
                      file: {{test.filename}},
                      line: {{test.line_number}},
                      end_line: {{test.end_line_number}},
                      focus: {{focus}},
                      tags: {{tags}}
                    ) do
                      instance.{{test.name.id}} *args
                    end
                  end
                {% else %}
                  {% data_source.raise %(Unsupported "Data" source return type: "#{data_source.return_type}") %}
                {% end %}
              {% end %}
            {% end %}
          {% end %}
        end
      {% end %}

      instance
    end

    # Method executed before the first test in the current class runs.
    #
    # ```
    # ExampleTest < Testify::Test
    #   def before_all : Nil
    #     puts "before_all"
    #   end
    # end
    # ```
    def before_all : Nil
    end

    # Method executed before each test in the current class runs.
    #
    # ```
    # ExampleTest < Testify::Test
    #   def before_each : Nil
    #     puts "before_each"
    #   end
    # end
    # ```
    def before_each : Nil
    end

    # Method executed after the last test in the current class runs.
    #
    # ```
    # ExampleTest < Testify::Test
    #   def after_all : Nil
    #     puts "after_all"
    #   end
    # end
    # ```
    def after_all : Nil
    end

    # Method executed after each test in the current class runs.
    #
    # ```
    # ExampleTest < Testify::Test
    #   def after_each : Nil
    #     puts "after_each"
    #   end
    # end
    # ```
    def after_each : Nil
    end

    # Method executed when the current class runs.
    #
    # ```
    # ExampleTest < Testify::Test
    #   def around_all(test) : Nil
    #     puts "around_all: before"
    #     test.run
    #     puts "around_all: after"
    #   end
    # end
    # ```
    def around_all(procsy) : Nil
      procsy.run
    end

    # Method executed when each test in the current class runs.
    #
    # ```
    # ExampleTest < Testify::Test
    #   def around_each(test) : Nil
    #     puts "around_each: before"
    #     test.run
    #     puts "around_each: after"
    #   end
    # end
    # ```
    def around_each(procsy) : Nil
      procsy.run
    end

    # Helper macro DSL for defining a test method.
    #
    # ```
    # require "spec"
    # require "testify"
    #
    # class ExampleTest < Testify::Test
    #   test "2 is even" do
    #     2.even?.should be_true
    #   end
    # end
    #
    # ExampleTest.run
    # ```
    private macro test(name, focus = false, *tags, &block)
      {% if focus %}@[Focus]{% end %}
      {% unless tags.empty? %}@[Tags({{tags.splat}})]{% end %}
      def test_{{name.gsub(/\ /, "_").underscore.downcase.id}} : Nil
        {{ block.body }}
      end
    end
  end
end

require "./tracer"
