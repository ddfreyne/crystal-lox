class Parser
  class ParseError < Exception
  end

  def initialize(@tokens : Array(Token))
    @current = 0
  end

  def parse : Array(Stmt)
    statements = [] of Stmt

    while !at_end?
      statements << declaration
    end

    statements
  end

  # expressions

  private def declaration : Stmt
    if match([TokenType::VAR])
      return var_declaration
    end

    statement
    # TODO: synchronize
  end

  private def var_declaration : Stmt
    name = consume(TokenType::IDENTIFIER, "Expected variable name.")

    initializer = nil
    if match([TokenType::EQUAL])
      initializer = expression
    end

    consume(TokenType::SEMICOLON, "Expected ';' after variable declaration.")
    Stmt::Var.new(name, initializer)
  end

  private def statement : Stmt
    if match([TokenType::PRINT])
      return print_statement
    end

    expression_statement
  end

  private def print_statement : Stmt
    value = expression
    consume(TokenType::SEMICOLON, "Expected ';' after value.")
    Stmt::Print.new(value)
  end

  private def expression_statement : Stmt
    expr = expression
    consume(TokenType::SEMICOLON, "Expected ';' after value.")
    Stmt::Expression.new(expr)
  end

  private def expression : Expr
    assignment
  end

  private def assignment : Expr
    expr = equality

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
      consume(TokenType::RIGHT_PAREN, "Expected ')' after expression.")
      Expr::Grouping.new(expr)
    else
      raise error(peek, "Expected expression.")
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

  # TODO: private def synchronize
end
