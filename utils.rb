# Lame ripoff of Dart's method cascade syntax via Object#do method
class Object
  def do(&block)
    self.instance_exec(&block) if block
    self
  end
end
