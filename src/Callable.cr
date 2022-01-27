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
  end
end
