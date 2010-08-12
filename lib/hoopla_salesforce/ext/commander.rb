# Automatically include the executable and command name
# in the syntax statment
class Commander::Command
  def syntax=(syntax)
    @syntax = "#{HooplaSalesforce.name} #{@name} #{syntax}"
  end
end
