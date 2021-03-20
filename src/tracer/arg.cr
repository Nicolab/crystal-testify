# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

class Testify::Tracker::Tracer(A)
  # Represents an argument provided to the `Tracer` (used by `Trace`).
  class Arg(T)
    @name : String

    def initialize(name : String | Symbol, @value : T)
      @name = name.to_s
    end

    # Argument name.
    def name : String
      @name
    end

    # Argument value.
    def value : T
      @value
    end
  end
end
