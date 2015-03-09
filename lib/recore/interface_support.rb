module ReCore::InterfaceSupport
  def subclass_must_implement(clazz)
    bt = caller(1)
    method = bt[0].slice(/`([^']+)'$/, 1)
    raise NoMethodError, "Implementation class #{self.class.name} must implement #{clazz}##{method}", bt
  end
  private :subclass_must_implement
end
