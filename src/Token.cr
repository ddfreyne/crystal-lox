class Token
  def initialize(@type : TokenType, @lexeme : String, @literal : String | Nil, @line : Int32)
  end

  def to_s
    [type, lexeme, literal].join(" ")
  end
end
