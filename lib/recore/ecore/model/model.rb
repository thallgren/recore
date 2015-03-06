module ReCore
module Ecore
module Model

EMPTY_ARRAY = [].freeze
EMPTY_HASH = {}.freeze
S_TRUE = 'true'.freeze
S_FALSE = 'false'.freeze

class EModelElement
  # @param annotation [EAnnotation]
  # @api private
  def add_annotation(annotation)
    @annotations ||= []
    @annotations << annotation
  end

  # @return [Array<EAnnotation>]
  # @api public
  def annotations
    @annotations.nil? ? EMPTY_ARRAY : @annotations.freeze
  end

  # @param package [EPackage]
  # @api private
  def resolve(package)
  end
end

class ENamedElement < EModelElement
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    @name = attributes['name']
  end

  # @return [String]
  def name
    @name
  end
end

class ETypedElement < ENamedElement
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super
    @ordered = (attributes['ordered'] || S_TRUE) == S_TRUE
    @unique = (attributes['unique'] || S_FALSE) == S_TRUE
    @lower_bound = (attributes['lowerBound'] || 0).to_i
    @upper_bound = (attributes['upperBound'] || 1).to_i
    @e_type_uri = attributes['eType']
    @generic_type = nil
  end

  # @return [EClassifier]
  def e_type
    @e_type
  end

  # @return [EGenericType]
  def generic_type
    @generic_type
  end

  # @param generic_type [EGenericType]
  # @api private
  def generic_type=(generic_type)
    @generic_type = generic_type
  end

  # @param package [EPackage]
  # @api private
  def resolve(package)
    super
    @e_type = package.resolve_uri(@e_type_uri) unless @e_type_uri.nil?
  end
end

class EAnnotation < EModelElement
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    @source = attributes['source']
    refs = attributes['references']
    @reference_uris = refs.nil? ? EMPTY_ARRAY : refs.split(/\s+/)
  end

  # @param key [String]
  # @param value [String]
  # @api private
  def add_detail(key, value)
    @details ||= {}
    @details[key] = value
  end

  # @param content [Object]
  # @api private
  def add_content(content)
    @contents ||= []
    @contents << content
  end

  # @return [String]
  def source
    @source
  end

  # @return [String]
  def references
    @references.nil? ? EMPTY_ARRAY : @references.freeze
  end

  # param package [EPackage]
  # @api private
  def resolve(package)
    super
    @references = @reference_uris.map {|uri| package.resolve_uri(uri)}
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
  # @param eclass [EClass]
  # @api private
  def add_class(eclass)
    @classes ||= {}
    @classes[eclass.name] = eclass
    eclass.package = self
  end

  # @param data_type [EDataType]
  # @api private
  def add_data_type(data_type)
    @data_types ||= {}
    @data_types[data_type.name] = data_type
    data_type.package = self
  end

  # @param subpackage [EPackage]
  # @api private
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

  # param package [EPackage]
  # @api private
  def package=(package)
    @package = package
  end

  # @return [EPackage]
  def package
    @package
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
    raise ParseError "Unable to resolve uri #{uri}"
  end

  # @return [Hash<String,EPackage>]
  def subpackages
    @subpackages.nil? ? EMPTY_HASH : @subpackages.freeze
  end
end

class EClassifier < ENamedElement
  # @param type_parameter [ETypeParameter]
  # @api private
  def add_type_parameter(type_parameter)
    @type_parameters ||= []
    @type_parameters << type_parameter
  end

  # param package [EPackage]
  # @api private
  def package=(package)
    @package = package
  end

  # @return [EPackage]
  def package
    @package
  end

  # @return [Array<ETypeParameter>]
  def type_parameters
    @type_parameters.nil? ? EMPTY_ARRAY : @type_parameters.freeze
  end
end

class EClass < EClassifier
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super(attributes)
    super_uris = attributes['eSuperTypes']
    @super_type_uris = super_uris.nil? ? EMPTY_ARRAY : super_uris.split(/\s+/)
    @abstract = (attributes['abstract'] || S_FALSE) == S_TRUE
    @interface = (attributes['interface'] || S_FALSE) == S_TRUE
    @attributes = nil
    @generic_super_types = nil
    @references = nil
    @operations = nil
  end

  def <=>(other)
    if assignable?(other)
      other.assignable?(self) ? name <=> other.name : -1
    elsif other.assignable?(self)
      1
    else
      super_types.reduce(-1) { |m, st| (st <=> other) >= 0 ? 1 : m }
    end
  end

  def abstract?
    @abstract
  end

  def assignable?(other)
    other.is_a?(EClass) && (other.equal?(self) || other.super_types.any? {|st| assignable?(st)})
  end

  # @param attribute [EAttribute]
  # @api private
  def add_attribute(attribute)
    @attributes ||= []
    @attributes << attribute
    attribute.containing_class = self
  end

  # @param generic_super_type [EGenericType]
  # @api private
  def add_generic_super_type(generic_super_type)
    @generic_super_types ||= []
    @generic_super_types << generic_super_type
  end

  # @param reference [EReference]
  # @api private
  def add_reference(reference)
    @references ||= []
    @references << reference
    reference.containing_class = self
  end

  # @param operation [EOperation]
  # @api private
  def add_operation(operation)
    @operations ||= []
    @operations << operation
    operation.containing_class = self
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

  # @return [Array<EOperation>]
  def operations
    @operations.nil? ? EMPTY_ARRAY : @operations.freeze
  end

  # @return [Array<EReference>]
  def references
    @references.nil? ? EMPTY_ARRAY : @references.freeze
  end

  # param package [EPackage]
  # @api private
  def resolve(package)
    super
    @super_types = @super_type_uris.map {|uri| package.resolve_uri(uri)}
  end

  # @return [Array<EClass>]
  def super_types
    @super_types
  end

  # @param path [Array<String>]
  # @return [ENamedElement]
  # @api private
  def resolve_path(path)
    path.reduce(self) {|memo, segment| break nil if memo.nil?; memo.resolve_segment(segment)}
  end

  # @param segment [String]
  # @return [ENamedElement]
  # @api private
  def resolve_segment(segment)
    attributes.each {|a| return a if a.name == segment}
    references.each {|r| return r if r.name == segment}
    operations.each {|o| return o if o.name == segment}
  end
end

class EDataType < EClassifier
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super(attributes)
    @instance_class_name = attributes['instanceClassName']
    @instance_type_name = attributes['instanceTypeName']
    @serializable = (attributes['serializable'] || S_TRUE) == S_TRUE
  end

  # @return [String]
  def instance_class_name
    @instance_class_name
  end

  # @return [String]
  def instance_type_name
    @instance_type_name
  end

  def serializable?
    @serializable
  end
end

class EEnumLiteral < ENamedElement
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super(attributes)
    @value = (attributes['value'] || 0).to_i
    @literal = attributes['literal'] || name
  end

  # @return [EEnum]
  def enum
    @enum
  end

  # @param enum [EEnum]
  # @api private
  def enum=(enum)
    @enum = enum
  end

  # @return [String]
  def literal
    @literal
  end

  # @return [Integer]
  def value
    @value
  end
end

class EEnum < EDataType
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super
    @literas = nil
  end

  # @param literal [EENumLiteral]
  # @api private
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

class EGenericType
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    @classifier_uri = attributes['eClassifier']
    @type_parameter_idref = attributes['eTypeParameter']
    @type_arguments = nil
  end

  # @param type_argument [EGenericType]
  # @api private
  def add_type_argument(type_argument)
    @type_arguments ||= []
    @type_arguments << type_argument
  end

  # @return [String]
  def classifier
    @classifier
  end

  # @return [EGenericType]
  def lower_bound
    @lower_bound
  end

  # @param lower_bound [EGenericType]
  # @api private
  def lower_bound=(lower_bound)
    @lower_bound = lower_bound
  end

  # param package [EPackage]
  # @api private
  def resolve(package)
    @classifier = package.resolve_uri(@classifier_uri) unless @classifier_uri.nil?
    @type_parameter = package.resolve_uri(@type_parameter_idref) unless @type_parameter_idref.nil?
  end

  # @return [String]
  def type_parameter
    @type_parameter
  end

  def type_arguments
    @type_arguments.nil? ? EMPTY_ARRAY : @type_arguments.freeze
  end

  # @param upper_bound [EGenericType]
  # @api private
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
  # @api private
  def initialize(attributes)
    super(attributes)
    @lower_bound = (attributes['lowerBound'] || '0').to_i
    @upper_bound = (attributes['upperBound'] || '1').to_i
    @changeable = (attributes['changeable'] || S_TRUE) == S_TRUE
    @derived = (attributes['derived'] || S_FALSE) == S_TRUE
    @volatile = (attributes['volatile'] || S_FALSE) == S_TRUE
    @transient = (attributes['transient'] || S_FALSE) == S_TRUE
    @unsettable = (attributes['unsettable'] || S_FALSE) == S_TRUE
    @default_value_literal = attributes['defaultValueLiteral']
  end

  def changeable?
    @changeable
  end

  # @return [EClass]
  def containing_class
    @containing_class
  end

  # @param containing_class [EClass]
  # @api private
  def containing_class=(containing_class)
    @containing_class = containing_class
  end

  # @return [String]
  def default_value_literal
    @default_value_literal
  end

  def derived?
    @derived
  end

  # @return [Integer]
  def lower_bound
    @lower_bound
  end

  def transient?
    @transient
  end

  def unsettable?
    @unsettable
  end

  # @return [Integer]
  def upper_bound
    @upper_bound
  end

  def volatile?
    @volatile
  end
end

class EAttribute < EStructuralFeature
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super(attributes)
    @id = (attributes['iD'] || S_FALSE) == 'true'
  end

  def id?
    @id
  end
end

class EReference < EStructuralFeature
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super(attributes)
    @resolve_proxies = (attributes['resolveProxies'] || S_TRUE) == S_TRUE
    @opposite_uri = attributes['eOpposite']
    @containment = (attributes['containment'] || S_FALSE) == S_TRUE
  end

  def containment?
    @containment
  end

  def resolve_proxies?
    @resolve_proxies
  end

  # @return [String]
  def opposite
    @opposite
  end

  # param package [EPackage]
  # @api private
  def resolve(package)
    super
    @opposite = package.resolve_uri(@opposite_uri) unless @opposite_uri.nil?
  end
end

class EParameter < ETypedElement
end

class ETypeParameter < ENamedElement
  # @param attributes [Hash<String,String>]
  # @api private
  def initialize(attributes)
    super(attributes)
    @bounds = []
  end

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
  # @api private
  def initialize(attributes)
    super(attributes)
    exceptions = attributes['eExceptions']
    @exception_uris = exceptions.nil? ? EMPTY_ARRAY : exceptions.split(/\s+/)
  end

  # @param parameter [EParameter]
  # @api private
  def add_parameter(parameter)
    @parameters ||= []
    @parameters << parameter
  end

  # @param type_parameter [ETypeParameter]
  # @api private
  def add_type_parameter(type_parameter)
    @type_parameters ||= []
    @type_parameters << type_parameter
  end

  # @return [EClass]
  def containing_class
    @containing_class
  end

  # @param containing_class [EClass]
  # @api private
  def containing_class=(containing_class)
    @containing_class = containing_class
  end

  # @return [String]
  def exceptions
    @exceptions
  end

  # @return [Array<EParameter>]
  def parameters
    @parameters.nil? ? EMPTY_ARRAY : @parameters.freeze
  end

  # @return [Array<TypeParameter]
  def type_parameters
    @type_parameters.nil? ? EMPTY_ARRAY : @type_parameters.freeze
  end

  # param package [EPackage]
  # @api private
  def resolve(package)
    super
    @exceptions = @exception_uris.map {|e| package.resolve_uri(e)}
  end
end
end
end
end

