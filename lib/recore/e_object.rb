module ReCore::EObject
  def e_class
    self.class.ancestors.each { |x| return x if !x.is_a?(Class) && x < ReCore::EObject }
  end
end

module ReCore::EObjectBuilder
  class EFeature
    attr_reader :name
    attr_reader :type
    attr_reader :props

    def initialize(name, type, props)
      @name = name
      @type = type
      @props = props
    end
  end

  def features
    @features ||= {}
    all = @features
    self.ancestors.each { |x| all.merge!(x.features) if !x.equal?(self) && x.respond_to?(:features) }
    all
  end

  def has_attr(sym, type, props = {})
    attr_reader sym
    features[sym] = EFeature.new(sym, type, props)
  end
end