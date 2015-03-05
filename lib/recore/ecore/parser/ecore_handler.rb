require 'recore/io/xml/parser'
require 'recore/ecore/parser/acceptor'

module ReCore::Ecore::Parser
  class Resolver
    include TraversalAcceptor

    def accept_EModelElement(e, args)
      super
      e.resolve(args)
    end
  end

  class ECoreHandler
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
      if @current.empty?
        Resolver.new.accept(element, element)
        @result = element
      end
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
      elem = EPackage.new(attributes)
      @current.last.add_subpackage(elem) unless @current.empty?
      @current.push(elem)
    end

    def eAnnotations(attributes)
      elem = EAnnotation.new(attributes)
      @current.last.add_annotation(elem)
      @current.push(elem)
    end

    def eBounds(attributes)
      elem = EGenericType.new(attributes)
      @current.last.add_bound(elem)
      @current.push(elem)
    end

    def eClasses(attributes)
      elem = EClass.new(attributes)
      @current.last.add_class(elem)
      @current.push(elem)
    end

    def eDataTypes(attributes)
      elem = EDataType.new(attributes)
      @current.last.add_data_type(elem)
      @current.push(elem)
    end

    def eEnums(attributes)
      elem = EEnum.new(attributes)
      @current.last.add_data_type(elem)
      @current.push(elem)
    end

    def eGenericType(attributes)
      elem = EGenericType.new(attributes)
      @current.last.generic_type = elem
      @current.push(elem)
    end

    def eGenericSuperTypes(attributes)
      elem = EGenericType.new(attributes)
      @current.last.add_generic_super_type(elem)
      @current.push(elem)
    end

    def eLiterals(attributes)
      elem = EEnumLiteral.new(attributes)
      @current.last.add_literal(elem)
      @current.push(elem)
    end

    def eLowerBound(attributes)
      elem = EGenericType.new(attributes)
      @current.last.lower_bound = elem
      @current.push(elem)
    end

    def eUpperBound(attributes)
      elem = EGenericType.new(attributes)
      @current.last.upper_bound = elem
      @current.push(elem)
    end

    def eOperations(attributes)
      elem = EOperation.new(attributes)
      @current.last.add_operation(elem)
      @current.push(elem)
    end

    def eParameters(attributes)
      elem = EParameter.new(attributes)
      @current.last.add_parameter(elem)
      @current.push(elem)
    end

    def eAttributes(attributes)
      elem = EAttribute.new(attributes)
      @current.last.add_attribute(elem)
      @current.push(elem)
    end

    def eReferences(attributes)
      elem = EReference.new(attributes)
      @current.last.add_reference(elem)
      @current.push(elem)
    end

    def eTypeArguments(attributes)
      elem = EGenericType.new(attributes)
      @current.last.add_type_argument(elem)
      @current.push(elem)
    end

    def eTypeParameters(attributes)
      elem = ETypeParameter.new(attributes)
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
