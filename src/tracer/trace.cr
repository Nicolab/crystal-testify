# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

class Testify::Tracker::Tracer(A)
  # Represents a trace.
  class Trace(A)
    @period : Time::Span
    @elapsed_time : Time::Span
    @args : Array(Arg(A))? = nil

    def initialize(from_period : Time::Span)
      @period = Time.monotonic
      @elapsed_time = @period - from_period
    end

    def initialize(from_period : Time::Span, args : Array(Arg(A)))
      initialize(from_period)
      @args = args
    end

    # Period (`Time.monotonic`) of the trace creation.
    def period : Time::Span
      @period
    end

    # Elasped time from the start period (*from_period* provided to `initialize`).
    def elapsed_time : Time::Span
      @elapsed_time
    end

    # Returns arguments added to the `Trace` instance.
    def args : Array(Arg(A))
      @args.not_nil!
    end

    # Returns arguments added to the `Trace` instance.
    def args? : Array(Arg(A))?
      @args
    end

    # Returns the arguments values provided to the `Trace`.
    def args_values? : Array(A)?
      return nil unless @args
      @args.map &.value
    end
  end
end
