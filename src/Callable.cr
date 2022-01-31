module Callable
  abstract def arity : Int32
  abstract def call(interpreter : Interpreter, arguments : Array(LoxValue))

  module Builtin
    class Clock
      include Callable

      def arity : Int32
        0
      end

      def call(interpreter : Interpreter, arguments : Array(LoxValue))
        Time.local.to_unix_f
      end

      def to_s
        "<native fn>"
      end
    end

    class Getc
      include Callable

      def arity : Int32
        0
      end

      def call(interpreter : Interpreter, arguments : Array(LoxValue))
        char = STDIN.read_char
        char ? char.ord.to_f : -1.0
      end

      def to_s
        "<native fn>"
      end
    end

    class Chr
      include Callable

      def arity : Int32
        1
      end

      def call(interpreter : Interpreter, arguments : Array(LoxValue))
        # p [:arguments, arguments, arguments.map { |a| a.class }]
        arg = arguments[0]?
        if arg.is_a?(Float64)
          arg.to_i.unsafe_chr.to_s
        else
          nil
        end
      end

      def to_s
        "<native fn>"
      end
    end
  end
end
