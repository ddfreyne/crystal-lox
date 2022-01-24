abstract class Stmt
  module Visitor
    abstract def visit_block_stmt(expr : Block) : Void
    abstract def visit_expression_stmt(expr : Expression) : Void
    abstract def visit_if_stmt(expr : If) : Void
    abstract def visit_print_stmt(expr : Print) : Void
    abstract def visit_var_stmt(expr : Var) : Void
  end

  abstract def accept(visitor : Visitor)

  class Block < Stmt
    getter stmts

    def initialize(@stmts : Array(Stmt))
    end

    def accept(visitor : Visitor)
      visitor.visit_block_stmt(self)
    end
  end

  class Expression < Stmt
    getter expression

    def initialize(@expression : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_expression_stmt(self)
    end
  end

  class If < Stmt
    getter condition
    getter then_branch
    getter else_branch

    def initialize(@condition : Expr, @then_branch : Stmt, @else_branch : Stmt | Nil)
    end

    def accept(visitor : Visitor)
      visitor.visit_if_stmt(self)
    end
  end

  class Print < Stmt
    getter expression

    def initialize(@expression : Expr)
    end

    def accept(visitor : Visitor)
      visitor.visit_print_stmt(self)
    end
  end

  class Var < Stmt
    getter name
    getter initializer

    def initialize(@name : Token, @initializer : Expr | Nil)
    end

    def accept(visitor : Visitor)
      visitor.visit_var_stmt(self)
    end
  end
end
