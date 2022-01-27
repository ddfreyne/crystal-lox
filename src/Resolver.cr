class Resolver
  include Expr::Visitor
  include Stmt::Visitor

  enum FunctionType
    NONE
    FUNCTION
  end

  def initialize(@interpreter : Interpreter)
    @scopes = [] of Hash(String, Bool)
    @current_function_type = FunctionType::NONE
  end

  def resolve(stmts : Array(Stmt))
    stmts.each { |stmt| resolve(stmt) }
  end

  def resolve(stmt : Stmt)
    stmt.accept(self)
  end

  def resolve(expr : Expr)
    expr.accept(self)
  end

  # statements

  def visit_block_stmt(stmt : Stmt::Block) : Void
    begin_scope
    resolve(stmt.stmts)
    end_scope
    nil
  end

  def visit_class_stmt(stmt : Stmt::Class) : Void
    declare(stmt.name)
    define(stmt.name)

    # TODO: declare/define methods
  end

  def visit_expression_stmt(stmt : Stmt::Expression) : Void
    resolve(stmt.expression)
  end

  def visit_function_stmt(stmt : Stmt::Function) : Void
    declare(stmt.name)
    define(stmt.name)

    resolve_function(stmt, FunctionType::FUNCTION)
  end

  def visit_if_stmt(stmt : Stmt::If) : Void
    resolve(stmt.condition)
    resolve(stmt.then_branch)
    else_branch = stmt.else_branch
    if else_branch
      resolve(else_branch)
    end
  end

  def visit_print_stmt(stmt : Stmt::Print) : Void
    resolve(stmt.expression)
  end

  def visit_return_stmt(stmt : Stmt::Return) : Void
    if @current_function_type == FunctionType::NONE
      Lox.error(stmt.keyword, "Can't return from top-level code.")
    end

    value = stmt.value
    if value
      resolve(value)
    end
  end

  def visit_var_stmt(stmt : Stmt::Var) : Void
    declare(stmt.name)
    initializer = stmt.initializer
    if initializer
      resolve(initializer)
    end
    define(stmt.name)
  end

  def visit_while_stmt(stmt : Stmt::While) : Void
    resolve(stmt.condition)
    resolve(stmt.body)
  end

  # expressions

  def visit_assign_expr(expr : Expr::Assign)
    resolve(expr.value)
    resolve_local(expr, expr.name)
  end

  def visit_binary_expr(expr : Expr::Binary)
    resolve(expr.left)
    resolve(expr.right)
  end

  def visit_call_expr(expr : Expr::Call)
    resolve(expr.callee)
    expr.arguments.each { |arg| resolve(arg) }
  end

  def visit_literal_expr(expr : Expr::Literal)
  end

  def visit_logical_expr(expr : Expr::Logical)
    resolve(expr.left)
    resolve(expr.right)
  end

  def visit_grouping_expr(expr : Expr::Grouping)
    resolve(expr.expr)
  end

  def visit_unary_expr(expr : Expr::Unary)
    resolve(expr.right)
  end

  def visit_variable_expr(expr : Expr::Variable)
    if @scopes.any? && @scopes.last[expr.name.lexeme]? == false
      Lox.error(expr.name, "Can't read local variable in its own initializer.")
    end

    resolve_local(expr, expr.name)
  end

  # helpers

  def begin_scope
    @scopes.push({} of String => Bool)
  end

  def end_scope
    @scopes.pop
  end

  def declare(name : Token)
    return if @scopes.empty?

    scope = @scopes.last

    if scope.has_key?(name.lexeme)
      Lox.error(name, "Already a variable with this name in this scope.")
    end

    scope[name.lexeme] = false # declared but not defined
  end

  def define(name : Token)
    return if @scopes.empty?

    scope = @scopes.last
    scope[name.lexeme] = true # declared and defined
  end

  def resolve_local(expr : Expr, name : Token)
    (@scopes.size - 1).downto(0) do |i|
      scope = @scopes[i]
      if scope.has_key?(name.lexeme)
        @interpreter.resolve(expr, @scopes.size - 1 - i)
        return
      end
    end
  end

  def resolve_function(function : Stmt::Function, function_type : FunctionType)
    enclosing_function_type = @current_function_type
    @current_function_type = function_type

    begin_scope

    function.params.each do |param|
      declare(param)
      define(param)
    end

    resolve(function.body)

    end_scope
    @current_function_type = enclosing_function_type
  end
end
