# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

module TestSupport
  class TargetTest < Testify::Test
    include Testify::Tracker

    def initialize
      @tracer = LogTracer.new
      log_trace(:initialize)
    end

    def log_trace(name : String | Symbol, message : String? = nil) : Nil
      @tracer.add(name, message)
    end

    def tracer_size(name : String | Symbol) : Int32
      @tracer.size(name)
    end

    def tracer : LogTracer
      @tracer
    end

    # ----------------------------------------------------------------------------
    # Hooks
    # ----------------------------------------------------------------------------

    def before_all : Nil
      tracer_size(:before_all).should eq 0
      log_trace :before_all
    end

    def before_each : Nil
      log_trace :before_each
    end

    def after_all : Nil
      tracer_size(:after_all).should eq 0
      log_trace :after_all
    end

    def after_each : Nil
      log_trace :after_each
    end

    def around_all(procsy) : Nil
      tracer_size(:around_all).should eq 0
      log_trace :around_all
      procsy.run
      log_trace :around_all_after_run
    end

    def around_each(procsy) : Nil
      log_trace :around_each
      procsy.run
      log_trace :around_each_after_run
    end

    # ----------------------------------------------------------------------------
    # Methods
    # ----------------------------------------------------------------------------

    def never_called
      fail %(TargetTest#never_called was called)
    end

    def self.never_called
      fail %(TargetTest.never_called was called)
    end

    # ----------------------------------------------------------------------------
    # Tests
    # ----------------------------------------------------------------------------

    def test_add : Nil
      log_trace :test_add
    end

    test "sub" do
      log_trace :test_sub
    end

    def ptest_pending : Nil
      log_trace :ptest_pending
    end
  end
end
