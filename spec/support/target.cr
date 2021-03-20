# This file is part of "Testify" project.
#
# This source code is licensed under the MIT license, please view the LICENSE
# file distributed with this source code. For the full
# information and documentation: https://github.com/Nicolab/crystal-testify
# ------------------------------------------------------------------------------

module TestSupport
  class Target
    def initialize(@tracer : Testify::Tracker::LogTracer)
    end

    def never_called
      fail %(Target#never_called was called)
    end

    def self.never_called
      fail %(Target.never_called was called)
    end

    def add(a, b)
      result = a + b
      @tracer.add(:target_add, "#{result}")
      result
    end

    def sub(a, b)
      result = a - b
      @tracer.add(:target_sub, "#{result}")
      result
    end
  end
end
