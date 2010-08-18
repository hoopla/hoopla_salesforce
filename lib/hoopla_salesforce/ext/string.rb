class String
  def margin
    spaces = match(/^\s*/)
    gsub(/^#{spaces[0]}/, '')
  end

  def camelize(first_letter_in_uppercase = true)
    if first_letter_in_uppercase
      gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
    else
      first.downcase + camelize(lower_case_and_underscored_word)[1..-1]
    end
  end
end
