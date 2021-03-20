# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

module Testify::Tracker
  # A simple `Tracer` implementation that logs calls.
  # By default it logs the number of calls of the `add` method
  # but it is possible to specify a different message to the `add` method.
  #
  # ```
  # class ExampleTest < Testify::Test
  #   include Testify::Tracker
  #
  #   def initialize
  #     @tracer = LogTracer.new
  #     log_trace(:initialize)
  #     log_trace(:key_is_a_symbol_or_string)
  #     log_trace("foo", "bar")
  #     log_trace("foo", "another trace for foo")
  #   end
  #
  #   def log_trace(name : String | Symbol, message : String? = nil) : Nil
  #     @tracer.add(name, message)
  #   end
  #
  #   def tracer_size(name : String | Symbol) : Int32
  #     @tracer.size(name)
  #   end
  #
  #   def tracer : LogTracer
  #     @tracer
  #   end
  #
  #   def test_example_tracer
  #     tracer_size("foo").should eq 2
  #
  #     # debug
  #     pp tracer.get("foo")
  #   end
  # end
  # ```
  class LogTracer
    @tracer : Tracer(String)

    def initialize
      @tracer = Tracer(String).new
    end

    # Creates a trace referenced to the *name* namespace.
    # The default *message* is the increment number of the current call (`#1, #2, #3, ...`).
    # See `Tracer#add`.
    def add(name : String | Symbol, message : String? = nil)
      @tracer.add name, [message.nil? || message.empty? ? "##{size(name) + 1}" : message]
    end

    # Returns the number of traces performed.
    # See `Tracer#size`.
    def size(name : String | Symbol) : Int32
      @tracer.size(name)
    end

    # Returns all traces.
    # See `Tracer#traces`.
    def traces
      @tracer.traces
    end

    # Returns the `Tracer` instance used by the `LogTracer` instance.
    def tracer : Tracer(String)
      @tracer
    end
  end
end
