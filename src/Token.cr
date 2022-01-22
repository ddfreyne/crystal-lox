class Token
  getter type
  getter lexeme

  def initialize(@type : TokenType, @lexeme : String, @literal : String | Nil | Float64, @line : Int32)
  end

  def to_s
    [@type, @lexeme, @literal || "null"].join(" ")
  end
end
