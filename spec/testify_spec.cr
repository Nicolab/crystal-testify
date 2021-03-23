# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

require "./spec_helper"

describe Testify do
  # Runs all tests of all `Test` classes
  tests = Testify.run_all

  it "should run all Test classes and return them" do
    tests.size.should eq 2
    tests.should be_a Hash(String, Testify::Test)
    tests.has_key?("TestSupport::TargetTest").should be_true
    tests.has_key?("TestSupport::ChildTargetTest").should be_true
  end

  it "run all tests of each Test classes" do
    # TargetTest
    tracer1 = tests["TestSupport::TargetTest"].tracer
    tracer1.traces.size.should eq 11

    # Tests
    tracer1.size(:initialize).should eq 1
    tracer1.size(:test_add).should eq 1
    tracer1.size(:test_sub).should eq 1
    tracer1.size(:ptest_pending).should eq 0

    # Lifecycle hooks
    tracer1.size(:before_all).should eq 1
    tracer1.size(:before_each).should eq 2
    tracer1.size(:after_all).should eq 1
    tracer1.size(:after_each).should eq 2
    tracer1.size(:around_all).should eq 1
    tracer1.size(:around_all_after_run).should eq 1
    tracer1.size(:around_each).should eq 2
    tracer1.size(:around_each_after_run).should eq 2

    # ChildTargetTest
    tracer2 = tests["TestSupport::ChildTargetTest"].tracer
    tracer2.traces.size.should eq 18

    # Tests
    tracer2.size(:initialize).should eq 1
    tracer2.size(:test_add).should eq 1
    tracer2.size(:test_sub).should eq 1
    tracer2.size(:ptest_pending).should eq 0
    tracer2.size(:test_child_skip).should eq 0
    tracer2.size(:test_child_pending).should eq 0
    tracer2.size(:test_child_tags).should eq 0

    # Data
    tracer2.size(:test_with_data).should eq 5 # (2 * by get_data) + (3 * by get_other_data)
    tracer2.size(:target_child_get_data).should eq 1
    tracer2.size(:target_child_get_other_data).should eq 1

    # Lifecycle hooks
    tracer2.size(:before_all).should eq 0 # overloaded by the child class (don't call super)
    tracer2.size(:before_all_from_child).should eq 1
    tracer2.size(:before_each).should eq 9            # overloaded by the child class (call super)
    tracer2.size(:before_each_from_child).should eq 9 # called from child
    tracer2.size(:after_all).should eq 1
    tracer2.size(:after_each).should eq 0            # overloaded by the child class (don't call super)
    tracer2.size(:after_each_from_child).should eq 9 # called from child
    tracer2.size(:around_all).should eq 1
    tracer2.size(:around_all_after_run).should eq 1
    tracer2.size(:around_all_from_child).should eq 1
    tracer2.size(:around_each).should eq 9
    tracer2.size(:around_each_after_run).should eq 9
  end

  it "should execute only the focused test case method" do
    code = <<-CODE
    require "spec"
    require "./src/testify"

    class FocusTest < Testify::Test
      def test_thing : Nil
        puts "test_thing executed"
      end

      def ftest_focus : Nil
        puts "ftest_focus executed"
      end
    end

    FocusTest.run
    CODE

    output = `crystal eval #{Process.quote(code)}`
    $?.success?.should be_true
    output.should contain "Finished in"
    output.should contain "ftest_focus executed"
    output.should_not contain "test_thing executed"
    output.should contain "1 examples, 0 failures, 0 errors, 0 pending"
    output.should contain "Only running `focus: true`"
  end
end

# NOTE: other tests are in the ./support directory.
