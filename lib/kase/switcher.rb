require "kase/errors"

module Kase
  class Switcher
    def initialize(values)
      if values.size == 1 && values.first.is_a?(Array)
        values = values.first
      end
      @values = values
      @matched = false
    end

    attr_reader :values, :context, :result

    def matched?
      !!@matched
    end

    def match?(*pattern)
      values[0...pattern.size] == pattern
    end

    def on(pattern, context, &blk)
      return if matched?
      return unless match?(*pattern)
      @matched = true
      @result = context.instance_exec(*values[pattern.size..-1], &blk)
    end

    def validate!
      raise NoMatchError unless matched?
      true
    end

    def switch(&block)
      context = eval("self", block.binding)
      dsl = DSL.new(self, context)

      dsl.instance_eval(&block)
      validate!
      result
    end

    class DSL
      def initialize(switcher, context)
        @switcher = switcher
        @context = context
      end

      def on(*args, &block)
        @switcher.on(args, @context, &block)
      end

      def method_missing(method, *args, &block)
        @context.send(method, *args, &block)
      end
    end
  end
end
