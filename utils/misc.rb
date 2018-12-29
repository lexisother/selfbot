class Object
  # Lame ripoff of Dart's method cascade syntax via Object#do method
  def do(&block)
    self.instance_exec(&block) if block
    self
  end

  def check_type(*types, **opts)
    return self if self.nil? && opts[:nil]
    return self if types.any? {|x| self.is_a?(x) }

    type, name = self.class, opts.fetch(:name, '?')
    raise TypeError, "Invalid type #{type} for '#{name}'"
  end
end
