require 'recore/ecore/model/model'

module ReCore::Ecore::Model
  class DslEStructuredFeature
    # @param type_mapper [ReCore::Ecore::TypeMapper]
    # @param feature [EStructuredFeature]
    def initialize(type_mapper, feature)
      @type_mapper = type_mapper
      @feature = feature
    end
  end

  class DslProps
    # @param type_mapper [ReCore::Ecore::TypeMapper]
    # @param eclass [EClass]
    def initialize(type_mapper, eclass)
      @type_mapper = type_mapper
      @eclass = eclass
    end

    def _prop(prop, name, type, required, many, &block)
      prop.name = name
      prop.e_type = "#//#{type}"
      prop.lower_bound = required ? 1 : 0
      prop.upper_bound = many ? -1 : 1
      DslEStructuredFeature.new(prop, @type_mapper).instance_eval(&block) if block_given?
    end
  end

  class DslEClassAttrs < DslProps
    def _attr(name, type, required = false, many = false, &block)
      attr = EAttribute.new
      @eclass.add_attribute(attr)
      type = @type_mapper.ruby_to_ecore(type) if type.is_a?(Class)
      _prop(attr, name,  type, required, many, &block)
    end

    def one(name, type, required = false, &block)
      _attr(name, type, required, false, &block)
    end

    def many(name, type, &block)
      _attr(name, type, false, true, &block)
    end
  end

  class DslEClassRefs < DslProps
    # @param type_mapper [ReCore::Ecore::TypeMapper]
    # @param eclass [EClass]
    # @param containment [Boolean]
    def initialize(type_mapper, eclass, containment)
      super(type_mapper, eclass)
      @containment = containment
    end

    def _ref(name, type, required, opposite, keys, many, &block)
      ref = EReference.new
      @eclass.add_reference(ref)
      ref.containment = @containment
      ref.opposite = "#//#{type}/#{opposite}" unless opposite.nil?
      ref.keys = keys.map { |k| "#//#{k}" } unless keys.nil?
      _prop(ref, name, type, required, many, &block)
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
    def initialize(type_mapper, eclass)
      @type_mapper = type_mapper
      @eclass = eclass
    end

    def abstract
      @eclass.abstract = true
    end

    def attributes(&block)
      DslEClassAttrs.new(@type_mapper, @eclass).instance_eval(&block)
    end

    def containments(&block)
      DslEClassRefs.new(@type_mapper, @eclass, true).instance_eval(&block)
    end

    def interface
      @eclass.interface = true
    end

    def references(&block)
      DslEClassRefs.new(@type_mapper, @eclass, false).instance_eval(&block)
    end

    def super_class(name)
      super_classes(name)
    end

    def super_classes(*names)
      @eclass.super_types = names.map { |n| "#//#{n}" }
    end
  end

  class DslEPackage
    def initialize(type_mapper, package)
      @type_mapper = type_mapper
      @package = package
    end

    def add_class(name, &block)
      eclass = EClass.new
      eclass.name = name
      @package.add_class(eclass)
      DslEClass.new(@type_mapper, eclass).instance_eval(&block) if block_given?
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
      handler = ReCore::Ecore::Model::Handler.new
      parser = ReCore::IO::XML::Parser.new(handler)
      File.open(File.join(RECORE_ROOT, 'model', 'Ecore.ecore')) do |file|
        parser.parse(file)
      end
      @ecore = handler.result
      @package = EPackage.new
      @type_mapper = ReCore::Ecore::TypeMapper::ECORE_MAPPER
    end

    def package(name, ns_uri = nil, &block)
      package = @package
      package.name = name
      package.ns_uri = ns_uri
      package.ns_prefix = name.downcase
      DslEPackage.new(@type_mapper, package).instance_eval &block
      package
    end

    def resolve
      ReCore::Ecore::Model::Resolver.new.accept(@package, self)
      @package
    end

    def resolve_uri(uri)
      begin
        @package.resolve_uri(uri)
      rescue ArgumentError
        @ecore.resolve_uri(uri)
      end
    end
  end
end