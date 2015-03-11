require 'recore/io/xml/parser'

module ReCore::Ecore::Parser

  class Handler
    include ReCore::IO::XML::Handler
    include ReCore::Ecore::Model

    # @return [EPackage]
    def result
      @result
    end

    def initialize
      @current = []
      attrs = {}.compare_by_identity
      attrs[ENamedElement] = keys(
        'name' => :name=)

      attrs[EAnnotation] = keys(
        'source' => :source=,
        'references' => :references=)

      attrs[EGenericType] = keys(
        'eClassifier' => :classifier=,
        'eTypeParameter' => :type_parameter=)

      attrs[EClassifier] = attrs[ENamedElement].merge(keys(
          'instanceClassName' => :instance_class_name=,
          'instanceTypeName' => :instance_type_name=))

      attrs[EClass] = attrs[EClassifier].merge(keys(
          'abstract' => :abstract=,
          'interface' => :interface=,
          'eSuperTypes' => :super_types=))

      attrs[EDataType] = attrs[EClassifier].merge(keys(
          'serializable' => :serializable=))

      attrs[EEnum] = attrs[EDataType]

      attrs[EEnumLiteral] = attrs[ENamedElement].merge(keys(
          'value' => :value=,
          'literal' => :literal=))

      attrs[EPackage] = attrs[ENamedElement].merge(keys(
          'nsURI' => :ns_uri=,
          'nsPrefix' => :ns_prefix=,
          'eFactoryInstance' => :factory_instance=))

      attrs[ETypedElement] = attrs[ENamedElement].merge(keys(
          'eType' => :e_type=,
          'lowerBound' => :lower_bound=,
          'ordered' => :ordered=,
          'unique' => :unique=,
          'upperBound' => :upper_bound=))

      attrs[EOperation] = attrs[ETypedElement].merge(keys(
          'eExceptions' => :exceptions=))

      attrs[EParameter] = attrs[ETypedElement]
      attrs[ETypeParameter] = attrs[ENamedElement]

      attrs[EStructuralFeature] = attrs[ETypedElement].merge(keys(
          'changeable' => :changeable=,
          'defaultValueLiteral' => :default_value_literal=,
          'derived' => :derived=,
          'transient' => :transient=,
          'unsettable' => :unsettable=,
          'volatile' => :volatile=))

      attrs[EAttribute] = attrs[EStructuralFeature].merge(keys(
          'iD' => :id=))
      attrs[EReference] = attrs[EStructuralFeature].merge(keys(
          'containment' => :containment=,
          'eOpposite' => :opposite=,
          'resolveProxies' => :resolve_proxies=,
          'eKeys' => :keys=))

      @attrs = attrs
      @key_attr = AttributeKey.new(namespace, 'key', nil)
      @value_attr = AttributeKey.new(namespace, 'value', nil)
    end

    def new_with_attributes(clazz, attributes)
      instance = clazz.new
      assign_attribute_values(instance, @attrs[clazz], attributes)
      instance
    end

    def namespace
      'http://www.eclipse.org/emf/2002/Ecore'
    end

    def parser=(parser)
      @parser = parser
    end

    def end_element(tag)
      element = @current.pop
      @result = element if @current.empty?
    end

    def eClassifiers(attributes)
      xsi_t = xsi_type(attributes)
      case xsi_t
      when 'EClass'
        eClasses(attributes)
      when 'EDataType'
        eDataTypes(attributes)
      when 'EEnum'
        eEnums(attributes)
      else
        raise ParseError "Unrecognized eClassifier type '#{xsi_t}'"
      end
    end

    def eStructuralFeatures(attributes)
      xsi_t = xsi_type(attributes)
      case xsi_t
      when 'EAttribute'
        eAttributes(attributes)
      when 'EReference'
        eReferences(attributes)
      else
        raise ParseError "Unrecognized eStructuralFeatures type '#{xsi_t}'"
      end
    end

    def details(attributes)
      @current.last.add_detail(*values(attributes, @key_attr, @value_attr))
      @current.push(nil) # since this is followed by a pop in end_element
    end

    def EPackage(attributes)
      e = new_with_attributes(EPackage, attributes)
      @current.last.add_subpackage(e) unless @current.empty?
      @current.push(e)
    end

    def eAnnotations(attributes)
      e = new_with_attributes(EAnnotation, attributes)
      @current.last.add_annotation(e)
      @current.push(e)
    end

    def eBounds(attributes)
      e = new_with_attributes(EGenericType, attributes)
      @current.last.add_bound(e)
      @current.push(e)
    end

    def eClasses(attributes)
      e = new_with_attributes(EClass, attributes)
      @current.last.add_class(e)
      @current.push(e)
    end

    def eDataTypes(attributes)
      e = new_with_attributes(EDataType, attributes)
      @current.last.add_data_type(e)
      @current.push(e)
    end

    def eEnums(attributes)
      e = new_with_attributes(EEnum, attributes)
      @current.last.add_data_type(e)
      @current.push(e)
    end

    def eGenericType(attributes)
      e = new_with_attributes(EGenericType, attributes)
      @current.last.generic_type = e
      @current.push(e)
    end

    def eGenericSuperTypes(attributes)
      e = new_with_attributes(EGenericType, attributes)
      @current.last.add_generic_super_type(e)
      @current.push(e)
    end

    def eLiterals(attributes)
      e = new_with_attributes(EEnumLiteral, attributes)
      @current.last.add_literal(e)
      @current.push(e)
    end

    def eLowerBound(attributes)
      e = new_with_attributes(EGenericType, attributes)
      @current.last.lower_bound = e
      @current.push(e)
    end

    def eUpperBound(attributes)
      e = new_with_attributes(EGenericType, attributes)
      @current.last.upper_bound = e
      @current.push(e)
    end

    def eOperations(attributes)
      e = new_with_attributes(EOperation, attributes)
      @current.last.add_operation(e)
      @current.push(e)
    end

    def eParameters(attributes)
      e = new_with_attributes(EParameter, attributes)
      @current.last.add_parameter(e)
      @current.push(e)
    end

    def eAttributes(attributes)
      e = new_with_attributes(EAttribute, attributes)
      @current.last.add_attribute(e)
      @current.push(e)
    end

    def eReferences(attributes)
      e = new_with_attributes(EReference, attributes)
      @current.last.add_reference(e)
      @current.push(e)
    end

    def eTypeArguments(attributes)
      e = new_with_attributes(EGenericType, attributes)
      @current.last.add_type_argument(e)
      @current.push(e)
    end

    def eTypeParameters(attributes)
      e = new_with_attributes(ETypeParameter, attributes)
      @current.last.add_type_parameter(e)
      @current.push(e)
    end
  end
end
