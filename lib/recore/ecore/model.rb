module ReCore
module Ecore
module Model

EMPTY_ARRAY = [].freeze
EMPTY_HASH = {}.freeze
S_TRUE = 'true'.freeze
S_FALSE = 'false'.freeze

# @abstract
class BaseElement
  # @param value [Array<Object>,String]
  # @return [Array<Object>,nil]
  def array_or_nil(value)
    unless value.nil?
      value = value.split(/\s+/) if value.is_a?(String)
      value = nil if value.empty?
    end
    value
  end

  # @param value [Boolean,String,nil]
  # @return [Boolean,nil]
  def bool_or_nil(value)
    value = value.downcase == S_TRUE if value.is_a?(String)
    value
  end

  # @param value [Boolean,nil]
  # @param default [Boolean]
  # @return [Boolean]
  def bool(value, default)
    value.nil? ? default : value
  end

  # @param value [Integer,String,nil]
  # @return [Integer,nil]
  def int_or_nil(value)
    value = value.to_i if value.is_a?(String)
    value
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
    @annotations || EMPTY_ARRAY
  end
end

# @abstract
class ENamedElement < EModelElement
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
  # @return [EClassifier]
  def e_type
    @e_type
  end

  # @param e_type [String]
  def e_type=(e_type)
    @e_type = e_type
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
    @lower_bound || 0
  end

  # @param lower_bound [Integer,String,nil]
  def lower_bound=(lower_bound)
    @lower_bound = int_or_nil(lower_bound)
  end

  def ordered?
    bool(@ordered, true)
  end

  # @param ordered [Boolean,String,nil]
  def ordered=(ordered)
    @ordered = bool_or_nil(ordered)
  end

  def unique?
    bool(@unique, false)
  end

  # @param unique [Boolean,String,nil]
  def unique=(unique)
    @unique = bool_or_nil(unique)
  end

  # @return [Integer]
  def upper_bound
    @upper_bound || 1
  end

  # @param upper_bound [Integer,String,nil]
  def upper_bound=(upper_bound)
    @upper_bound = upper_bound
  end
end

class EAnnotation < EModelElement
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
    @references || EMPTY_ARRAY
  end

  # @param references [String,Array<String>]
  def references=(references)
    @references = array_or_nil(references)
  end

  # @return [Map<String,String>]
  def details
    @details || EMPTY_HASH
  end

  # @return [Array<Object>]
  def contents
    @contents || EMPTY_ARRAY
  end
end

class EPackage < ENamedElement
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
    @classes || EMPTY_HASH
  end

  # @return [Hash<String,EDataType>]
  def data_types
    @data_types || EMPTY_HASH
  end

  # @return [EFactory|String]
  def factory_instance
    @factory_instance
  end

  # @param factory_instance [EFactory|String]
  def factory_instance=(factory_instance)
    @factory_instance = factory_instance
  end

  # Special inspect method needed to avoid endless recursion since Ruby doesn't do
  # a very good job of detecting such conditions.
  def inspect
    bld = StringIO.new
    bld << to_s
    bld.printf("\n @name=\"%s\",", name) unless name.nil?
    bld.printf("\n @ns_uri=\"%s\",", @ns_uri) unless @ns_uri.nil?
    bld.printf("\n @ns_prefix=\"%s\",", ns_prefix) unless ns_prefix.nil?
    unless @classes.nil?
      @classes.keys.sort.reduce("\n @classes=[") { |m,c| bld << m; bld << c; ',' }
      bld << '],'
    end
    unless @data_types.nil?
      @data_types.keys.sort.reduce("\n @data_types=[") { |m,c| bld << m; bld << c; ',' }
      bld << '],'
    end
    unless @subpackages.nil?
      @data_types.keys.sort.reduce("\n @subpackages=[") { |m,c| bld << m; bld << c; ',' }
      bld << '],'
    end
    bld.pos = bld.pos - 1
    bld << '>'
    bld.string
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

  # @return [Hash<String,EPackage>]
  def subpackages
    @subpackages || EMPTY_HASH
  end
end

class EClassifier < ENamedElement
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
    @type_parameters || EMPTY_ARRAY
  end
end

class EClass < EClassifier
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
    bool(@abstract, false)
  end

  # @param abstract [Boolean,String,nil]
  def abstract=(abstract)
    @abstract = bool_or_nil(abstract)
  end

  # @param attribute [EAttribute]
  def add_attribute(attribute)
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
    @attributes || EMPTY_ARRAY
  end

  # @return [Array<EGenericType>]
  def generic_super_types
    @generic_super_types || EMPTY_ARRAY
  end

  def interface?
    bool(@interface, false)
  end

  # @param interface [Boolean,String,nil]
  def interface=(interface)
    @interface = bool_or_nil(interface)
  end

  # @return [Array<EOperation>]
  def operations
    @operations || EMPTY_ARRAY
  end

  # @return [Array<EReference>]
  def references
    @references || EMPTY_ARRAY
  end

  # @return [Array<EClass|String>]
  def super_types(nil_if_missing=false)
    if @super_types.nil?
      nil_if_missing ? nil : EMPTY_ARRAY
    else
      @super_types
    end
  end

  # @param super_types [Array<String>]
  def super_types=(super_types)
    @super_types = array_or_nil(super_types)
  end
end

class EDataType < EClassifier
  def serializable?
    bool(@serializable, false)
  end

  # @param serializable [Boolean,String,nil]
  def serializable=(serializable)
    @serializable = bool_or_nil(serializable)
  end
end

class EEnumLiteral < ENamedElement
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
    @value || 0
  end

  # @param value [Integer]
  def value=(value)
    @value = int_or_nil(value)
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
    @literals || EMPTY_ARRAY
  end
end

class EGenericType < BaseElement
  # @param type_argument [EGenericType]
  def add_type_argument(type_argument)
    @type_arguments ||= []
    @type_arguments << type_argument
  end

  # @return [EClassifier|String]
  def classifier
    @classifier
  end

  # @param classifier [EClassifier|String]
  def classifier=(classifier)
    @classifier = classifier
  end

  # @return [EGenericType]
  def lower_bound
    @lower_bound
  end

  # @param lower_bound [EGenericType]
  def lower_bound=(lower_bound)
    @lower_bound = lower_bound
  end

  # @return [ETypeParameter|String]
  def type_parameter
    @type_parameter
  end

  # @param type_parameter [ETypeParameter|String]
  def type_parameter=(type_parameter)
    @type_parameter = type_parameter
  end

  # @return [Array<ETypeArgument>]
  def type_arguments
    @type_arguments || EMPTY_ARRAY
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
  def changeable?
    bool(@changeable, true)
  end

  # @param changeable [Boolean,String,nil]
  def changeable=(changeable)
    @changeable = bool_or_nil(changeable)
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
    bool(@derived, false)
  end

  # @param derived [Boolean,String,nil]
  def derived=(derived)
    @derived = bool_or_nil(derived)
  end

  def transient?
    bool(@transient, false)
  end

  # @param transient [Boolean,String,nil]
  def transient=(transient)
    @transient = transient
  end

  def unsettable?
    bool(@unsettable, false)
  end

  # @param unsettable [Boolean,String,nil]
  def unsettable=(unsettable)
    @unsettable = bool_or_nil(unsettable)
  end

  def volatile?
    bool(@volatile, false)
  end

  # @param volatile [Boolean,String,nil]
  def volatile=(volatile)
    @volatile = bool_or_nil(volatile)
  end
end

class EAttribute < EStructuralFeature
  def id?
    bool(@id, false)
  end

  # @param id [Boolean,String,nil]
  def id=(id)
    @id = bool_or_nil(id)
  end
end

class EReference < EStructuralFeature
  def containment?
    bool(@containment, false)
  end

  # @param containment [Boolean,String,nil]
  def containment=(containment)
    @containment = bool_or_nil(containment)
  end

  # @return [Array<String|EAttribute>]
  def keys(nil_if_missing=false)
    if @keys.nil? then
      nil_if_missing ? nil : EMPTY_ARRAY
    else
      @keys
    end
  end

  # @param keys [Array<String|EAttribute>,String,nil]
  def keys=(keys)
    @keys = array_or_nil(keys)
  end

  # @return [EReference|String]
  def opposite
    @opposite
  end

  # @param opposite [EReference|String]
  def opposite=(opposite)
    @opposite = opposite
  end

  def resolve_proxies?
    bool(@resolve_proxies, true)
  end

  # @param resolve_proxies [Boolean,String,nil]
  def resolve_proxies=(resolve_proxies)
    @resolve_proxies = bool_or_nil(resolve_proxies)
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
    @bounds || EMPTY_ARRAY
  end
end

class EOperation < ETypedElement
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

  # @return [Array<EClassifier|String>]
  def exceptions(nil_if_missing = false)
    if @exceptions.nil? then
      nil_if_missing ? nil : EMPTY_ARRAY
    else
      @exceptions
    end
  end

  # @param exceptions [Array<EClassifier|String>,String,nil]
  def exceptions=(exceptions)
    @exceptions = array_or_nil(exceptions)
  end

  # @return [Array<EParameter>]
  def parameters
    @parameters || EMPTY_ARRAY
  end

  # @return [Array<TypeParameter]
  def type_parameters
    @type_parameters || EMPTY_ARRAY
  end
end
end
end
end

