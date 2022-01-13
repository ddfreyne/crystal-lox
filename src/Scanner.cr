class Scanner
  def initialize(@source : String)
  end

  def scan_tokens
    # TODO: WIP
    @source.split(/\s+/)
  end
end
