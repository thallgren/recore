require 'recore/io/xml/parser'

module ReCore::Ecore::Parser
  Model = ReCore::Ecore::Model

  class Handler
    include ReCore::IO::XML::Handler

    # @return [EPackage]
    def result
      @result
    end

    def initialize
      @current = []
      attrs = {}
      attrs[Model::ENamedElement] = keys(
          'name' => :name=)

      attrs[Model::EAnnotation] = keys(
          'source' => :source=,
          'references' => :references=)

      attrs[Model::EGenericType] = keys(
          'eClassifier' => :classifier=,
          'eTypeParameter' => :type_parameter=)

      attrs[Model::EClassifier] = attrs[Model::ENamedElement].merge(keys(
          'instanceClassName' => :instance_class_name=,
          'instanceTypeName' => :instance_type_name=))

      attrs[Model::EClass] = attrs[Model::EClassifier].merge(keys(
          'abstract' => :abstract=,
          'interface' => :interface=,
          'eSuperTypes' => :super_types=))

      attrs[Model::EDataType] = attrs[Model::EClassifier].merge(keys(
          'serializable' => :serializable=))

      attrs[Model::EEnum] = attrs[Model::EDataType]

      attrs[Model::EEnumLiteral] = attrs[Model::ENamedElement].merge(keys(
          'value' => :value=,
          'literal' => :literal=))

      attrs[Model::EPackage] = attrs[Model::ENamedElement].merge(keys(
          'nsURI' => :ns_uri=,
          'nsPrefix' => :ns_prefix=,
          'eFactoryInstance' => :factory_instance=))

      attrs[Model::ETypedElement] = attrs[Model::ENamedElement].merge(keys(
        'eType' => :e_type=,
        'lowerBound' => :lower_bound=,
        'ordered' => :ordered=,
        'unique' => :unique=,
        'upperBound' => :upper_bound=))

      attrs[Model::EOperation] = attrs[Model::ETypedElement].merge(keys(
        'eExceptions' => :exceptions=))

      attrs[Model::EParameter] = attrs[Model::ETypedElement]
      attrs[Model::ETypeParameter] = attrs[Model::ENamedElement]

      attrs[Model::EStructuralFeature] = attrs[Model::ETypedElement].merge(keys(
        'changeable' => :changeable=,
        'defaultValueLiteral' => :default_value_literal=,
        'derived' => :derived=,
        'transient' => :transient=,
        'unsettable' => :unsettable=,
        'volatile' => :volatile=))

      attrs[Model::EAttribute] = attrs[Model::EStructuralFeature].merge(keys(
          'iD' => :id=))
      attrs[Model::EReference] = attrs[Model::EStructuralFeature].merge(keys(
          'containment' => :containment=,
          'eOpposite' => :opposite=,
          'resolveProxies' => :resolve_proxies=,
          'eKeys' => :keys=))

      @attrs = attrs
      @key_attr = ReCore::IO::XML::AttributeKey.new(namespace, 'key', nil)
      @value_attr = ReCore::IO::XML::AttributeKey.new(namespace, 'value', nil)
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
      e = new_with_attributes(Model::EPackage, attributes)
      @current.last.add_subpackage(e) unless @current.empty?
      @current.push(e)
    end

    def eAnnotations(attributes)
      e = new_with_attributes(Model::EAnnotation, attributes)
      @current.last.add_annotation(e)
      @current.push(e)
    end

    def eBounds(attributes)
      e = new_with_attributes(Model::EGenericType , attributes)
      @current.last.add_bound(e)
      @current.push(e)
    end

    def eClasses(attributes)
      e = new_with_attributes(Model::EClass, attributes)
      @current.last.add_class(e)
      @current.push(e)
    end

    def eDataTypes(attributes)
      e = new_with_attributes(Model::EDataType, attributes)
      @current.last.add_data_type(e)
      @current.push(e)
    end

    def eEnums(attributes)
      e = new_with_attributes(Model::EEnum, attributes)
      @current.last.add_data_type(e)
      @current.push(e)
    end

    def eGenericType(attributes)
      e = new_with_attributes(Model::EGenericType , attributes)
      @current.last.generic_type = e
      @current.push(e)
    end

    def eGenericSuperTypes(attributes)
      e = new_with_attributes(Model::EGenericType , attributes)
      @current.last.add_generic_super_type(e)
      @current.push(e)
    end

    def eLiterals(attributes)
      e = new_with_attributes(Model::EEnumLiteral, attributes)
      @current.last.add_literal(e)
      @current.push(e)
    end

    def eLowerBound(attributes)
      e = new_with_attributes(Model::EGenericType , attributes)
      @current.last.lower_bound = e
      @current.push(e)
    end

    def eUpperBound(attributes)
      e = new_with_attributes(Model::EGenericType , attributes)
      @current.last.upper_bound = e
      @current.push(e)
    end

    def eOperations(attributes)
      e = new_with_attributes(Model::EOperation, attributes)
      @current.last.add_operation(e)
      @current.push(e)
    end

    def eParameters(attributes)
      e = new_with_attributes(Model::EParameter, attributes)
      @current.last.add_parameter(e)
      @current.push(e)
    end

    def eAttributes(attributes)
      e = new_with_attributes(Model::EAttribute, attributes)
      @current.last.add_attribute(e)
      @current.push(e)
    end

    def eReferences(attributes)
      e = new_with_attributes(Model::EReference, attributes)
      @current.last.add_reference(e)
      @current.push(e)
    end

    def eTypeArguments(attributes)
      e = new_with_attributes(Model::EGenericType , attributes)
      @current.last.add_type_argument(e)
      @current.push(e)
    end

    def eTypeParameters(attributes)
      e = new_with_attributes(Model::ETypeParameter, attributes)
      @current.last.add_type_parameter(e)
      @current.push(e)
    end
  end
end
