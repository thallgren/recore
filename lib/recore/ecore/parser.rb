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
      # The stack
      # @type [Array<String>]
      @current = []
    end

    def namespace
      'http://www.eclipse.org/emf/2002/Ecore'
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
      case xsi_type(attributes)
        when 'EAttribute'
          eAttributes(attributes)
        when 'EReference'
          eReferences(attributes)
        else
          raise ParseError "Unrecognized eStructuralFeatures type '#{xsi_t}'"
      end
    end

    def details(attributes)
      @current.last.add_detail(attributes['key'], attributes['value'])
      @current.push(nil) # since this is followed by a pop in end_element
    end

    def EPackage(attributes)
      elem = Model::EPackage.new
      elem.map_init(attributes)
      @current.last.add_subpackage(elem) unless @current.empty?
      @current.push(elem)
    end

    def eAnnotations(attributes)
      elem = Model::EAnnotation.new
      elem.map_init(attributes)
      @current.last.add_annotation(elem)
      @current.push(elem)
    end

    def eBounds(attributes)
      elem = Model::EGenericType.new
      elem.map_init(attributes)
      @current.last.add_bound(elem)
      @current.push(elem)
    end

    def eClasses(attributes)
      elem = Model::EClass.new
      elem.map_init(attributes)
      @current.last.add_class(elem)
      @current.push(elem)
    end

    def eDataTypes(attributes)
      elem = Model::EDataType.new
      elem.map_init(attributes)
      @current.last.add_data_type(elem)
      @current.push(elem)
    end

    def eEnums(attributes)
      elem = Model::EEnum.new
      elem.map_init(attributes)
      @current.last.add_data_type(elem)
      @current.push(elem)
    end

    def eGenericType(attributes)
      elem = Model::EGenericType.new
      elem.map_init(attributes)
      @current.last.generic_type = elem
      @current.push(elem)
    end

    def eGenericSuperTypes(attributes)
      elem = Model::EGenericType.new
      elem.map_init(attributes)
      @current.last.add_generic_super_type(elem)
      @current.push(elem)
    end

    def eLiterals(attributes)
      elem = Model::EEnumLiteral.new
      elem.map_init(attributes)
      @current.last.add_literal(elem)
      @current.push(elem)
    end

    def eLowerBound(attributes)
      elem = Model::EGenericType.new
      elem.map_init(attributes)
      @current.last.lower_bound = elem
      @current.push(elem)
    end

    def eUpperBound(attributes)
      elem = Model::EGenericType.new
      elem.map_init(attributes)
      @current.last.upper_bound = elem
      @current.push(elem)
    end

    def eOperations(attributes)
      elem = Model::EOperation.new
      elem.map_init(attributes)
      @current.last.add_operation(elem)
      @current.push(elem)
    end

    def eParameters(attributes)
      elem = Model::EParameter.new
      elem.map_init(attributes)
      @current.last.add_parameter(elem)
      @current.push(elem)
    end

    def eAttributes(attributes)
      elem = Model::EAttribute.new
      elem.map_init(attributes)
      @current.last.add_attribute(elem)
      @current.push(elem)
    end

    def eReferences(attributes)
      elem = Model::EReference.new
      elem.map_init(attributes)
      @current.last.add_reference(elem)
      @current.push(elem)
    end

    def eTypeArguments(attributes)
      elem = Model::EGenericType.new
      elem.map_init(attributes)
      @current.last.add_type_argument(elem)
      @current.push(elem)
    end

    def eTypeParameters(attributes)
      elem = Model::ETypeParameter.new
      elem.map_init(attributes)
      @current.last.add_type_parameter(elem)
      @current.push(elem)
    end

    private

    def xsi_type(attributes)
      xt = attributes['xsi:type']
      xt = xt[6..-1] if xt.start_with?('ecore:')
      xt
    end
  end
end
