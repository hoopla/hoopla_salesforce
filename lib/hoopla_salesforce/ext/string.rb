class String
  def margin
    spaces = match(/^\s*/)
    gsub(/^#{spaces[0]}/, '')
  end
end
