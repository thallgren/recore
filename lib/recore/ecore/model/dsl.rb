require 'recore/ecore/model/model'

module ReCore::Ecore::Model
  class DslEStructuredFeature
    # @param feature [EStructuredFeature]
    def initialize(feature)
      @feature = feature
    end
  end

  class DslEClassAttrs
    # @param eclass [EClass]
    def initialize(eclass)
      @eclass = eclass
    end

    def _attr(name, type, required = false, many = false, &block)
      attr = EAttribute.new
      attr.name = name
      attr.e_type_uri = "#//#{type}"
      attr.lower_bound = required ? 1 : 0
      attr.upper_bound = many ? -1 : 1
      @eclass.add_attribute(attr)
      DslEStructuredFeature.new(attr).instance_eval(&block) if block_given?
    end

    def one(name, type, required = false, &block)
      _attr(name, type, required, false, &block)
    end

    def many(name, type, &block)
      _attr(name, type, false, true, &block)
    end
  end

  class DslEClassRefs
    # @param eclass [EClass]
    def initialize(eclass, containment)
      @eclass = eclass
      @containment = containment
    end

    def _ref(name, type, required, opposite, keys, many, &block)
      ref = EReference.new
      ref.name = name
      ref.containment = @containment
      ref.opposite_uri = "#//#{type}" unless opposite.nil?
      ref.key_uris = keys.map { |k| "#//#{k}" } unless keys.nil?
      ref.e_type_uri = "#//#{type}"
      ref.lower_bound = required ? 1 : 0
      ref.upper_bound = many ? -1 : 1
      @eclass.add_reference(ref)
      DslEStructuredFeature.new(ref).instance_eval(&block) if block_given?
    end

    def one(name, type, required = false, opposite = nil, keys = nil, &block)
      _ref(name, type, required, opposite, keys, false, &block)
    end

    def many(name, type, opposite = nil, keys = nil, &block)
      _ref(name, type, false, opposite, keys, true, &block)
    end
  end

  class DslEClass
    # @param eclass [EClass]
    def initialize(eclass)
      @eclass = eclass
    end

    def abstract
      @eclass.abstract = true
    end

    def attributes(&block)
      DslEClassAttrs.new(@eclass).instance_eval(&block)
    end

    def containments(&block)
      DslEClassRefs.new(@eclass, true).instance_eval(&block)
    end

    def interface
      @eclass.interface = true
    end

    def references(&block)
      DslEClassRefs.new(@eclass, false).instance_eval(&block)
    end

    def super_class(name)
      super_classes(name)
    end

    def super_classes(*names)
      @eclass.super_type_uris = names.map { |n| "#//#{n}" }
    end
  end

  class DslEPackage
    def initialize(package)
      @package = package
    end

    def add_class(name, &block)
      eclass = EClass.new
      eclass.name = name
      @package.add_class(eclass)
      DslEClass.new(eclass).instance_eval(&block) if block_given?
    end

    def add_data_type(name, instance_class_name = nil, serializable = true)
      data_type = EDataType.new
      data_type.name = name
      data_type.instance_class_name = instance_class_name
      data_type.serializable = serializable
      @package.add_data_type(data_type)
    end
  end

  class DSL
    def initialize
      @package = EPackage.new
    end

    def package(name, ns_uri = nil, &block)
      package = @package
      package.ns_uri = ns_uri
      package.ns_prefix = name.downcase
      package.factory_instance_uri = "#//#{name}Factory"
      DslEPackage.new(package).instance_eval &block
      package
    end

    def resolve
      @package.resolve(@package)
    end
  end
end