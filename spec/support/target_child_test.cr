# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

module TestSupport
  class ChildTargetTest < TargetTest
    # ----------------------------------------------------------------------------
    # Hooks
    # ----------------------------------------------------------------------------

    def before_all : Nil
      tracer_size(:before_all_from_child).should eq 0
      log_trace :before_all_from_child
    end

    def before_each : Nil
      log_trace :before_each_from_child
      super
    end

    def after_each : Nil
      log_trace :after_each_from_child
    end

    def around_all(procsy) : Nil
      log_trace :around_all_from_child
      super
    end

    # ----------------------------------------------------------------------------
    # Methods
    # ----------------------------------------------------------------------------

    def never_called
      fail %(ChildTargetTest#never_called was called)
    end

    def self.never_called
      fail %(ChildTargetTest.never_called was called)
    end

    # ----------------------------------------------------------------------------
    # Tests
    # ----------------------------------------------------------------------------

    def test_child_add : Nil
      log_trace :test_child_add
    end

    def test_child_sub : Nil
      log_trace :test_child_sub
    end

    # Data Providers allow reusing a test's multiple times with different input.
    @[Data("get_data")]
    @[Data("get_other_data")]
    def test_with_data(value : Int32, expected : Int32) : Nil
      log_trace :test_with_data
      (value * 2).should eq expected
    end

    # Returns a hash where the key represents the name of the test,
    # and the value is a Tuple of data that should be provided to the test.
    def get_data : NamedTuple
      log_trace :target_child_get_data
      {
        by_two: {2, 4},
        by_ten: {10, 20},
      }
    end

    def get_other_data : NamedTuple
      log_trace :target_child_get_other_data
      {
        by_two:  {2, 4},
        by_ten:  {10, 20},
        by_four: {8, 16},
      }
    end

    @[Skip]
    def test_skip_annotation : Nil
      log_trace :test_child_skip
    end

    @[Pending]
    def test_pending_annotation : Nil
      log_trace :test_child_pending
    end

    @[Tags("ignore")]
    def test_tags_annotation : Nil
      log_trace :test_child_tags
    end
  end
end
