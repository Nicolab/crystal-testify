# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

# Tracking utilities to trace some behaviors (like a method call, an event listener, a `spawn`, a `Channel`, ...).
module Testify::Tracker
  # Creates a tracer that can trace calls, elapsed time, etc with some data.
  #
  # > See `LogTracer` for an example.
  class Tracer(A)
    @period : Time::Span

    def initialize
      @traces = Hash(String, Array(Trace(A))).new
      @period = Time.monotonic
    end

    # Period (`Time.monotonic`) of the tracer creation.
    def period : Time::Span
      @period
    end

    # Returns a `Hash` of all entries.
    def traces : Hash(String, Array(Trace(A)))
      @traces
    end

    # Creates a trace referenced to the *name* namespace.
    def add(name : String | Symbol, args : Array)
      name = name.to_s
      @traces[name] = [] of Trace(A) unless @traces.has_key?(name)
      i = 0
      @traces[name] << Trace.new period, args.map { |arg|
        Arg(typeof(arg)).new("#{name}##{i += 1}", arg)
      }
    end

    # Returns `true` if *name* has one or more traces.
    def has?(name : String | Symbol) : Bool
      name = name.to_s
      return false if !(list = @traces[name]?) || list.size === 0
      true
    end

    # Returns the numbers of traces for *name*.
    def size(name : String | Symbol) : Int32
      name = name.to_s
      return 0 if !(list = @traces[name]?)
      list.size
    end

    # Returns entries of *name*.
    def get(name : String | Symbol) : Array(Trace(A))
      @traces[name.to_s]
    end

    # Returns entries of *name*.
    def get?(name : String | Symbol) : Array(Trace(A))?
      @traces[name.to_s]?
    end

    # Returns `Trace` instance of *name* at *index*.
    def get(name : String | Symbol, index : Int32) : Trace(A)
      @traces[name.to_s][index]
    end

    # Returns `Trace` instance of *name* at *index*.
    def get?(name : String | Symbol, index : Int32) : Trace(A)?
      name = name.to_s
      return nil unless list = @traces[name]?
      list[name][index]?
    end

    # Returns `Trace` arguments added to *name* at *index*.
    def args?(name : String | Symbol, index : Int32) : Array(Arg(A))
      return nil unless trace = get?(name, index)
      trace.args?
    end

    # Returns the values of `Trace` arguments added to *name* at *index*.
    def args_values?(name : String | Symbol, index : Int32) : Array(A)
      return nil unless trace = get?(name, index)
      trace.args_values?
    end

    # Compares *args* with the `Trace` arguments added to *name* at *index*.
    def with_args?(name : String | Symbol, index : Int32, args : Array(Arg(A))) : Bool
      args == args?
    end

    # Compares *args* with the `Trace` arguments added to *name* at *index*.
    def with_args?(name : String | Symbol, index : Int32, args : Array) : Bool
      args == args_values?(name, index)
    end
  end
end

require "./tracer"
require "./arg"
require "./trace"
require "./log_tracer"
