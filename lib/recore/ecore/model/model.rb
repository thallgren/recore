module ReCore
module Ecore
module Model

EMPTY_ARRAY = [].freeze
EMPTY_HASH = {}.freeze
S_TRUE = 'true'.freeze
S_FALSE = 'false'.freeze

# @abstract
class BaseElement
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes = nil)
    map_init(attributes) if attributes.is_a?(Hash)
  end

  # @param resource [Resource]
  def resolve(resource)
  end

  # @param attributes [Hash<String,String>]
  # @api private
  def map_init(attributes)
  end

  # @param attributes [Hash<String,String>]
  # @param name [String]
  # @param default [Boolean]
  # @return [Boolean]
  def bool_arg(attributes, name, default)
    val = attributes[name]
    val.nil? ? default : val == S_TRUE
  end

  # @param attributes [Hash<String,String>]
  # @param name [String]
  # @param default [Integer]
  # @return [Integer]
  def int_arg(attributes, name, default)
    val = attributes[name]
    val.nil? ? default : val.to_i
  end

  # @param attributes [Hash<String,String>]
  # @param name [String]
  # @return [Array<String>]
  def array_arg(attributes, name)
    val = attributes[name]
    val.nil? ? EMPTY_ARRAY : val.split(/\s+/)
  end
end

# @abstract
class EModelElement < BaseElement
  # @param annotation [EAnnotation]
  def add_annotation(annotation)
    @annotations ||= []
    @annotations << annotation
  end

  # @return [Array<EAnnotation>]
  def annotations
    @annotations.nil? ? EMPTY_ARRAY : @annotations.freeze
  end
end

# @abstract
class ENamedElement < EModelElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @name = attributes['name']
  end

  # @return [String]
  def name
    @name
  end

  # @param name [String]
  def name=(name)
    @name = name
  end
end

class ETypedElement < ENamedElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @e_type_uri = attributes['eType']
    @lower_bound = int_arg(attributes, 'lowerBound', 0)
    @ordered = bool_arg(attributes, 'ordered', true)
    @unique = bool_arg(attributes, 'unique', false)
    @upper_bound = int_arg(attributes, 'upperBound', 1)
  end

  # @return [EClassifier]
  def e_type
    @e_type
  end

  # @return [String]
  def e_type_uri
    @e_type_uri
  end

  # @param e_type_uri [String]
  def e_type_uri=(e_type_uri)
    @e_type_uri = e_type_uri
  end

  # @return [EGenericType]
  def generic_type
    @generic_type
  end

  # @param generic_type [EGenericType]
  def generic_type=(generic_type)
    @generic_type = generic_type
  end

  # @return [Integer]
  def lower_bound
    @lower_bound
  end

  # @param lower_bound [Integer]
  def lower_bound=(lower_bound)
    @lower_bound = lower_bound
  end

  def ordered?
    @ordered
  end

  # @param ordered [Boolean]
  def ordered=(ordered)
    @ordered = ordered
  end

  # @param resource [Resource]
  def resolve(resource)
    @e_type = resource.resolve_uri(@e_type_uri) unless @e_type_uri.nil?
  end

  def unique?
    @unique
  end

  # @param unique [Boolean]
  def unique=(unique)
    @unique = unique
  end

  # @return [Integer]
  def upper_bound
    @upper_bound
  end

  # @param upper_bound [Integer]
  def upper_bound=(upper_bound)
    @upper_bound = upper_bound
  end
end

class EAnnotation < EModelElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @source = attributes['source']
    @reference_uris = array_arg(attributes, 'references')
  end

  # @param key [String]
  # @param value [String]
  def add_detail(key, value)
    @details ||= {}
    @details[key] = value
  end

  # @param content [Object]
  def add_content(content)
    @contents ||= []
    @contents << content
  end

  # @return [String]
  def source
    @source
  end

  # @param source [String]
  def source=(source)
    @source = source
  end

  # @return [Array<String>]
  def references
    @references.nil? ? EMPTY_ARRAY : @references
  end

  # @param references [Array<String>]
  def references=(references)
    @references = references
  end

  # @param resource [Resource]
  def resolve(resource)
    super
    @references = @reference_uris.map {|uri| resource.resolve_uri(uri)}
  end

  # @return [Map<String,String>]
  def details
    @details.nil? ? EMPTY_HASH : @details.freeze
  end

  # @return [Array<Object>]
  def contents
    @contents.nil? ? EMPTY_ARRAY : @contents.freeze
  end
end

class EPackage < ENamedElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @ns_uri = attributes['nsURI']
    @ns_prefix = attributes['nsPrefix']
    @factory_instance_uri = attributes['eFactoryInstance']
  end

  # @param eclass [EClass]
  def add_class(eclass)
    @classes ||= {}
    @classes[eclass.name] = eclass
    eclass.package = self
  end

  # @param data_type [EDataType]
  def add_data_type(data_type)
    @data_types ||= {}
    @data_types[data_type.name] = data_type
    data_type.package = self
  end

  # @param subpackage [EPackage]
  def add_subpackage(subpackage)
    @subpackages ||= {}
    @subpackages[subpackage.name] = subpackage
    subpackage.package = self
  end

  # @return [Hash<String,EClass>]
  def classes
    @classes.nil? ? EMPTY_HASH : @classes.freeze
  end

  # @return [Hash<String,EDataType>]
  def data_types
    @data_types.nil? ? EMPTY_HASH : @data_types.freeze
  end

  # @return [EFactory]
  def factory_instance
    @factory_instance
  end

  # @return [String]
  def factory_instance_uri
    @factory_instance_uri
  end

  # @param factory_instance_uri [String]
  def factory_instance_uri=(factory_instance_uri)
    @factory_instance_uri = factory_instance_uri
  end

  # @return [String]
  def ns_prefix
    @ns_prefix
  end

  # @param ns_prefix [String]
  def ns_prefix=(ns_prefix)
    @ns_prefix = ns_prefix
  end

  # @return [String]
  def ns_uri
    @ns_uri
  end

  # @param ns_uri [String]
  def ns_uri=(ns_uri)
    @ns_uri = ns_uri
  end

  # @return [EPackage]
  def package
    @package
  end

  # @param package [EPackage]
  def package=(package)
    @package = package
  end

  # @param resource [Resource]
  def resolve(resource)
    @factory_instance = resource.resolve_uri(@factory_instance_uri) unless @factory_instance_uri.nil?
  end

  def resolve_uri(uri)
    # TODO: Should delegate to Resource
    if uri.start_with?('#//')
      path = uri[3..-1].split('/')
      classifier_name = path[0]
      classifier = classes[classifier_name]
      if classifier.nil?
        classifier = data_types[classifier_name]
        if classifier.nil?
          classifier = subpackages[classifier_name]
        end
      end
      unless classifier.nil?
        return path.size > 1 ? classifier.resolve_path(path.drop(1)) : classifier
      end
    end
    raise ArgumentError, "Unable to resolve uri #{uri}"
  end

  # @return [Hash<String,EPackage>]
  def subpackages
    @subpackages.nil? ? EMPTY_HASH : @subpackages.freeze
  end
end

class EClassifier < ENamedElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @instance_class_name = attributes['instanceClassName']
    @instance_type_name = attributes['instanceTypeName']
  end

  # @return [String]
  def instance_class_name
    @instance_class_name
  end

  # @param instance_class_name [String]
  def instance_class_name=(instance_class_name)
    @instance_class_name = instance_class_name
  end

  # @return [String]
  def instance_type_name
    @instance_type_name
  end

  # @param instance_type_name [String]
  def instance_type_name=(instance_type_name)
    @instance_type_name = instance_type_name
  end

  # @param type_parameter [ETypeParameter]
  def add_type_parameter(type_parameter)
    @type_parameters ||= []
    @type_parameters << type_parameter
  end

  # @return [EPackage]
  def package
    @package
  end

  # @param package [EPackage]
  def package=(package)
    @package = package
  end

  # @return [Array<ETypeParameter>]
  def type_parameters
    @type_parameters.nil? ? EMPTY_ARRAY : @type_parameters.freeze
  end
end

class EClass < EClassifier
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @abstract = bool_arg(attributes, 'abstract', false)
    @interface = bool_arg(attributes, 'interface', false)
    @super_type_uris = array_arg(attributes, 'eSuperTypes')
  end

  def <=>(other)
    if equal?(other)
      0
    elsif assignable?(other)
      -1
    elsif other.assignable?(self) || super_types.any? { |st| (st <=> other) >= 0 }
      1
    else
      cmp = super_chain(0) <=> other.super_chain(0)
      cmp == 0 ? name <=> other.name : cmp
    end
  end

  # @return [Integer]
  def super_chain(count)
    count += 1
    super_types.reduce(count) { |m, s| v = s.super_chain(count); v > m ? v : m }
  end

  def abstract?
    @abstract
  end

  # @param abstract [Boolean]
  def abstract=(abstract)
    @abstract = abstract
  end

  # @param attribute [EAttribute]
  def add_attribute(attribute = nil, &block)
    @attributes ||= []
    @attributes << attribute
    attribute.containing_class = self
  end

  # @param generic_super_type [EGenericType]
  def add_generic_super_type(generic_super_type)
    @generic_super_types ||= []
    @generic_super_types << generic_super_type
  end

  # @param reference [EReference]
  def add_reference(reference)
    @references ||= []
    @references << reference
    reference.containing_class = self
  end

  # @param operation [EOperation]
  def add_operation(operation)
    @operations ||= []
    @operations << operation
    operation.containing_class = self
  end

  def assignable?(other)
    other.is_a?(EClass) && (other.equal?(self) || other.super_types.any? {|st| assignable?(st)})
  end

  def attributes
    @attributes.nil? ? EMPTY_ARRAY : @attributes.freeze
  end

  # @return [Array<EGenericType>]
  def generic_super_types
    @generic_super_types.nil? ? EMPTY_ARRAY : @generic_super_types.freeze
  end

  def interface?
    @interface
  end

  # @param interface [Boolean]
  def interface=(interface)
    @interface = interface
  end

  # @return [Array<EOperation>]
  def operations
    @operations.nil? ? EMPTY_ARRAY : @operations.freeze
  end

  # @return [Array<EReference>]
  def references
    @references.nil? ? EMPTY_ARRAY : @references.freeze
  end

  # @param resource [Resource]
  def resolve(resource)
    super
    @super_types = @super_type_uris.map {|uri| resource.resolve_uri(uri)}
  end

  # @return [Array<EClass>]
  def super_types
    @super_types
  end

  # @return [Array<String>]
  def super_type_uris
    @super_type_uris
  end

  # @param super_type_uris [Array<String>]
  def super_type_uris=(super_type_uris)
    @super_type_uris = super_type_uris
  end

  # @param path [Array<String>]
  # @return [ENamedElement]
  def resolve_path(path)
    result = path.reduce(self) {|memo, segment| break nil if memo.nil?; memo.resolve_segment(segment)}
    raise ArgumentError "Unable to resolve path #{path.join('/')}" if result.nil?
    result
  end

  # @param segment [String]
  # @return [ENamedElement]
  def resolve_segment(segment)
    attributes.each {|a| return a if a.name == segment}
    references.each {|r| return r if r.name == segment}
    operations.each {|o| return o if o.name == segment}
  end
end

class EDataType < EClassifier
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @serializable = bool_arg(attributes, 'serializable', true)
  end

  def serializable?
    @serializable
  end

  # @param serializable [Boolean]
  def serializable=(serializable)
    @serializable = serializable
  end
end

class EEnumLiteral < ENamedElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @value = int_arg(attributes, 'value', 0)
    @literal = attributes['literal']
  end

  # @return [EEnum]
  def enum
    @enum
  end

  # @param enum [EEnum]
  def enum=(enum)
    @enum = enum
  end

  # @return [String]
  def literal
    @literal || name
  end

  # @param literal [String]
  def literal=(literal)
    @literal = literal
  end

  # @return [Integer]
  def value
    @value
  end

  # @param value [Integer]
  def value=(value)
    @value = value
  end
end

class EEnum < EDataType
  # @param literal [EENumLiteral]
  def add_literal(literal)
    @literals ||= []
    @literals << literal
    literal.enum = self
  end

  # @return [Array<EEnumLiteral>]
  def literals
    @literals.nil? ? EMPTY_ARRAY : @literals.freeze
  end
end

class EGenericType < BaseElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    @classifier_uri = attributes['eClassifier']
    @type_parameter_idref = attributes['eTypeParameter']
  end

  # @param type_argument [EGenericType]
  def add_type_argument(type_argument)
    @type_arguments ||= []
    @type_arguments << type_argument
  end

  # @return [EClassifier]
  def classifier
    @classifier
  end

  # @return [String]
  def classifier_uri
    @classifier_uri
  end

  # @param classifier_uri [String]
  def classifier_uri=(classifier_uri)
    @classifier_uri = classifier_uri
  end

  # @return [EGenericType]
  def lower_bound
    @lower_bound
  end

  # @param lower_bound [EGenericType]
  def lower_bound=(lower_bound)
    @lower_bound = lower_bound
  end

  # @param resource [Resource]
  def resolve(resource)
    @classifier = resource.resolve_uri(@classifier_uri) unless @classifier_uri.nil?
    @type_parameter = resource.resolve_uri(@type_parameter_idref) unless @type_parameter_idref.nil?
  end

  # @return [ETypeParameter]
  def type_parameter
    @type_parameter
  end

  # @return [String]
  def type_parameter_idref
    @type_parameter_idref
  end

  # @param type_parameter_idref [String]
  def type_parameter_idref=(type_parameter_idref)
    @type_parameter_idref = type_parameter_idref
  end

  # @return [Array<ETypeArgument>]
  def type_arguments
    @type_arguments.nil? ? EMPTY_ARRAY : @type_arguments.freeze
  end

  # @param upper_bound [EGenericType]
  def upper_bound=(upper_bound)
    @upper_bound = upper_bound
  end

  # @return [EGenericType]
  def upper_bound
    @upper_bound
  end
end

class EStructuralFeature < ETypedElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @changeable = bool_arg(attributes, 'changeable', true)
    @default_value_literal = attributes['defaultValueLiteral']
    @derived = bool_arg(attributes, 'derived', false)
    @transient = bool_arg(attributes, 'transient', false)
    @unsettable = bool_arg(attributes, 'unsettable', false)
    @volatile = bool_arg(attributes, 'volatile', false)
  end

  def changeable?
    @changeable
  end

  # @param changeable [Boolean]
  def changeable=(changeable)
    @changeable = changeable
  end

  # @return [EClass]
  def containing_class
    @containing_class
  end

  # @param containing_class [EClass]
  def containing_class=(containing_class)
    @containing_class = containing_class
  end

  # @return [String]
  def default_value_literal
    @default_value_literal
  end

  # @param default_value_literal [String]
  def default_value_literal=(default_value_literal)
    @default_value_literal = default_value_literal
  end

  def derived?
    @derived
  end

  # @param derived [Boolean]
  def derived=(derived)
    @derived = derived
  end

  def transient?
    @transient
  end

  # @param transient [Boolean]
  def transient=(transient)
    @transient = transient
  end

  def unsettable?
    @unsettable
  end

  # @param unsettable [Boolean]
  def unsettable=(unsettable)
    @unsettable = unsettable
  end

  def volatile?
    @volatile
  end

  # @param volatile [Boolean]
  def volatile=(volatile)
    @volatile = volatile
  end
end

class EAttribute < EStructuralFeature
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super(attributes)
    @id = bool_arg(attributes, 'iD', false)
  end

  def id?
    @id
  end

  # @param id [Boolean]
  def id=(id)
    @id = id
  end
end

class EReference < EStructuralFeature
  # @param attributes [Hash<String,String>]
  # @api private
  def map_init(attributes)
    super
    @containment = bool_arg(attributes, 'containment', false)
    @opposite_uri = attributes['eOpposite']
    @resolve_proxies = bool_arg(attributes, 'resolveProxies', true)
    @key_uris = array_arg(attributes, 'eKeys')
  end

  def containment?
    @containment
  end

  # @param containment [Boolean]
  def containment=(containment)
    @containment = containment
  end

  # @return [Array[EAttribute]]
  def keys
    @keys
  end

  # @return [Array<String>]
  def key_uris
    @key_uris
  end

  # @param key_uris [Array<String>]
  def key_uris=(key_uris)
    @key_uris = key_uris
  end

  # @return [EReference]
  def opposite
    @opposite
  end

  # @return [String]
  def opposite_uri
    @opposite_uri
  end

  # @param opposite_uri [String]
  def opposite_uri=(opposite_uri)
    @opposite_uri = opposite_uri
  end

  def resolve_proxies?
    @resolve_proxies
  end

  # @param resolve_proxies [Boolean]
  def resolve_proxies=(resolve_proxies)
    @resolve_proxies = resolve_proxies
  end

  # @param resource [Resource]
  def resolve(resource)
    super
    @opposite = resource.resolve_uri(@opposite_uri) unless @opposite_uri.nil?
    @keys = @key_uris.map { |k| resource.resolve_uri(k) }
  end
end

class EParameter < ETypedElement
end

class ETypeParameter < ENamedElement
  # @param bound [EGenericType]
  def add_bound(bound)
    @bounds ||= []
    @bounds << bound
  end

  # @return [Array<EGenericType]
  def bounds
    @bounds.nil? ? EMPTY_ARRAY : @bounds.freeze
  end
end

class EOperation < ETypedElement
  # @param attributes [Hash<String,String>]
  def map_init(attributes)
    super
    @exception_uris = array_arg(attributes, 'eExceptions')
  end

  # @param parameter [EParameter]
  def add_parameter(parameter)
    @parameters ||= []
    @parameters << parameter
  end

  # @param type_parameter [ETypeParameter]
  def add_type_parameter(type_parameter)
    @type_parameters ||= []
    @type_parameters << type_parameter
  end

  # @return [EClass]
  def containing_class
    @containing_class
  end

  # @param containing_class [EClass]
  def containing_class=(containing_class)
    @containing_class = containing_class
  end

  # @return [Array<EClassifier]
  def exceptions
    @exceptions
  end

  # @return [Array<String>]
  def exception_uris
    @exception_uris
  end

  # @param exception_uris [Array<String>]
  def exception_uris=(exception_uris)
    @exception_uris = exception_uris
  end

  # @return [Array<EParameter>]
  def parameters
    @parameters.nil? ? EMPTY_ARRAY : @parameters.freeze
  end

  # @return [Array<TypeParameter]
  def type_parameters
    @type_parameters.nil? ? EMPTY_ARRAY : @type_parameters.freeze
  end

  # @param resource [Resource]
  def resolve(resource)
    super
    @exceptions = @exception_uris.map {|e| resource.resolve_uri(e)}
  end
end
end
end
end

