class Parser
  class ParseError < Exception
  end

  def initialize(@tokens : Array(Token))
    @current = 0
  end

  def parse : Array(Stmt)
    statements = [] of Stmt

    while !at_end?
      stmt = declaration
      if stmt
        statements << stmt
      end
    end

    statements
  end

  # expressions

  private def declaration : Stmt | Nil
    if match([TokenType::VAR])
      return var_declaration
    end

    statement
  rescue
    synchronize
    nil
  end

  private def var_declaration : Stmt
    name = consume(TokenType::IDENTIFIER, "Expect variable name.")

    initializer = nil
    if match([TokenType::EQUAL])
      initializer = expression
    end

    consume(TokenType::SEMICOLON, "Expect ';' after variable declaration.")
    Stmt::Var.new(name, initializer)
  end

  private def statement : Stmt
    if match([TokenType::IF])
      return if_statement
    end

    if match([TokenType::PRINT])
      return print_statement
    end

    if match([TokenType::WHILE])
      return while_statement
    end

    if match([TokenType::LEFT_BRACE])
      return Stmt::Block.new(block)
    end

    expression_statement
  end

  private def if_statement : Stmt
    consume(TokenType::LEFT_PAREN, "Expect '(' after 'if'.")
    condition = expression
    consume(TokenType::RIGHT_PAREN, "Expect ')' after 'if'.")

    then_branch = statement
    else_branch = nil
    if match([TokenType::ELSE])
      else_branch = statement
    end

    Stmt::If.new(condition, then_branch, else_branch)
  end

  private def print_statement : Stmt
    value = expression
    consume(TokenType::SEMICOLON, "Expect ';' after value.")
    Stmt::Print.new(value)
  end

  private def while_statement : Stmt
    consume(TokenType::LEFT_PAREN, "Expect '(' after 'while'.")
    condition = expression
    consume(TokenType::RIGHT_PAREN, "Expect ')' after 'while'.")

    body = statement

    Stmt::While.new(condition, body)
  end

  private def expression_statement : Stmt
    expr = expression
    consume(TokenType::SEMICOLON, "Expect ';' after value.")
    Stmt::Expression.new(expr)
  end

  private def expression : Expr
    assignment
  end

  private def assignment : Expr
    expr = or

    if match([TokenType::EQUAL])
      equals = previous
      value = assignment

      case expr
      when Expr::Variable
        return Expr::Assign.new(expr.name, value)
      else
        # We report an error if the left-hand side isn’t a valid assignment
        # target, but we don’t throw it because the parser isn’t in a confused
        # state where we need to go into panic mode and synchronize.
        error(equals, "Invalid assignment target.")
      end
    end

    expr
  end

  private def or : Expr
    expr = and

    while match([TokenType::OR])
      operator = previous
      right = and
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  private def and : Expr
    expr = equality

    while match([TokenType::AND])
      operator = previous
      right = equality
      expr = Expr::Logical.new(expr, operator, right)
    end

    expr
  end

  private def equality : Expr
    expr = comparison

    while match([TokenType::BANG_EQUAL, TokenType::EQUAL_EQUAL])
      operator = previous
      right = comparison
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def comparison : Expr
    expr = term

    while match([TokenType::GREATER, TokenType::GREATER_EQUAL, TokenType::LESS, TokenType::LESS_EQUAL])
      operator = previous
      right = term
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def term : Expr
    expr = factor

    while match([TokenType::MINUS, TokenType::PLUS])
      operator = previous
      right = factor
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def factor : Expr
    expr = unary

    while match([TokenType::SLASH, TokenType::STAR])
      operator = previous
      right = unary
      expr = Expr::Binary.new(expr, operator, right)
    end

    expr
  end

  private def unary : Expr
    if match([TokenType::BANG, TokenType::MINUS])
      operator = previous
      right = unary
      return Expr::Unary.new(operator, right)
    end

    primary
  end

  private def primary : Expr
    if match([TokenType::FALSE])
      Expr::Literal.new(false)
    elsif match([TokenType::TRUE])
      Expr::Literal.new(true)
    elsif match([TokenType::NIL])
      Expr::Literal.new(nil)
    elsif match([TokenType::NUMBER, TokenType::STRING])
      Expr::Literal.new(previous.literal)
    elsif match([TokenType::IDENTIFIER])
      Expr::Variable.new(previous)
    elsif match([TokenType::LEFT_PAREN])
      expr = expression
      consume(TokenType::RIGHT_PAREN, "Expect ')' after expression.")
      Expr::Grouping.new(expr)
    else
      raise error(peek, "Expect expression.")
    end
  end

  # Utilities

  private def previous
    @tokens[@current - 1]
  end

  private def advance : Token
    if !at_end?
      @current += 1
    end

    previous
  end

  private def peek : Token
    @tokens[@current]
  end

  private def at_end? : Bool
    peek.type == TokenType::EOF
  end

  private def match(token_types : Array(TokenType)) : Bool
    token_types.each do |token_type|
      if check(token_type)
        advance
        return true
      end
    end

    false
  end

  private def check(token_type : TokenType) : Bool
    if at_end?
      false
    else
      peek.type == token_type
    end
  end

  private def consume(token_type : TokenType, message : String) : Token
    if check(token_type)
      return advance
    end

    raise error(peek, message)
  end

  private def error(token : Token, message : String) : ParseError
    Lox.error(token, message)
    ParseError.new
  end

  private def synchronize : Void
    advance

    while !at_end?
      if previous.type == TokenType::SEMICOLON
        return
      end

      case peek.type
      when TokenType::CLASS
        return
      when TokenType::FUN
        return
      when TokenType::VAR
        return
      when TokenType::FOR
        return
      when TokenType::IF
        return
      when TokenType::WHILE
        return
      when TokenType::PRINT
        return
      when TokenType::RETURN
        return
      end

      advance
    end
  end

  private def block : Array(Stmt)
    stmts = [] of Stmt

    while !check(TokenType::RIGHT_BRACE) && !at_end?
      stmt = declaration
      if stmt
        stmts << stmt
      end
    end

    consume(TokenType::RIGHT_BRACE, "Expect '}' after block.")

    stmts
  end
end
