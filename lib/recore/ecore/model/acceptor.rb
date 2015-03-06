require 'recore/ecore/model/model'

module ReCore::Ecore::Model

  module Acceptor
    METHOD_PREFIX = 'accept_'.freeze
    DOUBLE_COLON = '::'.freeze

    def accept(e, args)
      @@names ||= {}
      if (name = @@names[e.class]).nil?
        name = METHOD_PREFIX + e.class.name.split(DOUBLE_COLON).last
        @@names[e.class] = name
      end
      send(name, e, args) unless e.nil?
    end

    def accept_default(e, args)
    end

    def accept_EAnnotation(e, args)
      accept_EModelElement(e, args)
    end

    def accept_EAttribute(e, args)
      accept_EStructuralFeature(e, args)
    end

    def accept_EClass(e, args)
      accept_EClassifier(e, args)
    end

    def accept_EClassifier(e, args)
      accept_ENamedElement(e, args)
    end

    def accept_EDataType(e, args)
      accept_EClassifier(e, args)
    end

    def accept_EEnum(e, args)
      accept_EDataType(e, args)
    end

    def accept_EEnumLiteral(e, args)
      accept_ENamedElement(e, args)
    end

    def accept_EGenericType(e, args)
      accept_default(e, args)
    end

    def accept_EModelElement(e, args)
      accept_default(e, args)
    end

    def accept_ENamedElement(e, args)
      accept_EModelElement(e, args)
    end

    def accept_EOperation(e, args)
      accept_ETypedElement(e, args)
    end

    def accept_EPackage(e, args)
      accept_ENamedElement(e, args)
    end

    def accept_EParameter(e, args)
      accept_ETypedElement(e, args)
    end

    def accept_EReference(e, args)
      accept_EStructuralFeature(e, args)
    end

    def accept_EStructuralFeature(e, args)
      accept_ETypedElement(e, args)
    end

    def accept_ETypedElement(e, args)
      accept_ENamedElement(e, args)
    end

    def accept_ETypeParameter(e, args)
      accept_ENamedElement(e, args)
    end
  end

  module TraversalAcceptor
    include Acceptor

    def accept_EClass(e, args)
      super
      e.attributes.each {|a| accept(a, args)}
      e.references.each {|r| accept(r, args)}
      e.operations.each {|o| accept(o, args)}
      e.generic_super_types.each {|g| accept(g, args)}
    end

    def accept_EClassifier(e, args)
      super
      e.type_parameters.each {|t| accept(t, args)}
    end

    def accept_EGenericType(e, args)
      super
      accept(e.lower_bound, args)
      accept(e.upper_bound, args)
      e.type_arguments.each {|t| accept(t, args)}
    end

    def accept_EModelElement(e, args)
      super
      e.annotations.each {|a| accept(a, args)}
    end

    def accept_EPackage(e, args)
      super
      e.data_types.each_value {|d| accept(d, args)}
      e.classes.each_value {|c| accept(c, args)}
      e.subpackages.each_value {|s| accept(s, args)}
    end

    def accept_ETypeParameter(e, args)
      super
      e.bounds.each {|g| accept(g, args)}
    end

    def accept_EOperation(e, args)
      super
      e.parameters.each {|p| accept(p, args)}
      e.type_parameters.each {|t| accept(t, args)}
    end

    def accept_ETypedElement(e, args)
      super
      accept(e.generic_type, args)
    end
  end
end
