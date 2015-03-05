module ReCore::Ecore
  module Resource
    include ReCore::Util

    def contents
      subclass_must_implement Resource
    end

    def all_contents
      subclass_must_implement Resource
    end

    def get_EObject(uri_fragment)
      subclass_must_implement Resource
    end
  end

  module Enumerator
  end

  module EObject
    include ReCore::Util

    # @return [EClass] The ecore class of the object
    def e_class
      subclass_must_implement EObject
    end

    # @return [Resource] The containing resource
    def e_resource
      subclass_must_implement EObject
    end

    # @return [EObject] The containing ecore object
    def e_container
      subclass_must_implement EObject
    end

    # @return [Array<EObject>] The contained objects
    def e_contents
      subclass_must_implement EObject
    end

    # @return [Array<EObject>] All contained objects, direct and indirect
    def e_all_contents
      subclass_must_implement EObject
    end
  end

  module EGenericType
    include EObject
  end

  module EModelElement
    include EObject

    # @return [Array<EAnnotation>]
    def e_annotations
      subclass_must_implement EModelElement
    end

    # @param source [String]
    # @return [EAnnotation]
    def e_annotation(source)
      subclass_must_implement EModelElement
    end
  end

  module EAnnotation
    include EModelElement
  end

  module EFactory
    include EModelElement
  end

  module ECoreFactory
    include EFactory
  end

  module ENamedElement
    include EModelElement
  end

  module EClassifier
    include ENamedElement
  end

  module EPackage
    include ENamedElement
  end

  module EClass
    include EClassifier

    def abstract?
      subclass_must_implement EClass
    end

    def interface?
      subclass_must_implement EClass
    end

    # @param flag [Boolean]
    def abstract=(flag)
      subclass_must_implement EClass
    end

    # @param flag [Boolean]
    def interface=(flag)
      subclass_must_implement EClass
    end

    # @return [Array<EClass>]
    def e_id_attribute
      subclass_must_implement EClass
    end

    # @return [Array<EClass>]
    def e_supertypes
      subclass_must_implement EClass
    end

    def e_all_supertypes
      subclass_must_implement EClass
    end

    # @return [Array<EStructuralFeature>]
    def e_structural_features
      subclass_must_implement EClass
    end

    # @return [Array<EAttributes>]
    def e_attributes
      subclass_must_implement EClass
    end

    # @return [Array<EAttributes>]
    def e_all_attributes
      subclass_must_implement EClass
    end

    # @return [Array<EReference>]
    def e_references
      subclass_must_implement EClass
    end

    # @return [Array<EReference>]
    def e_all_references
      subclass_must_implement EClass
    end

    # @return [Array<EReference>]
    def e_all_containments
      subclass_must_implement EClass
    end

    # @return [Array<EOperation>]
    def e_operations
      subclass_must_implement EClass
    end

    # @return [Array<EOperation>]
    def e_all_operations
      subclass_must_implement EClass
    end

    def supertype_of?(some_class)
      subclass_must_implement EClass
    end

    # @return [Integer]
    def feature_count
      subclass_must_implement EClass
    end

    # @param feature [EStructuralFeature]
    # @return [Integer]
    def feature_id(feature)
      subclass_must_implement EClass
    end

    # @param feature [EStructuralFeature]
    # @return [EGenericType]
    def feature_type(feature)
      subclass_must_implement EClass
    end

    # @param feature_name_or_id [Integer|String]
    # @return EStructuralFeature
    def structural_feature(feature_name_or_id)
      subclass_must_implement EClass
    end

    # @return [Integer]
    def operation_count
      subclass_must_implement EClass
    end

    # @param operation_name_or_id [Integer|String]
    # @return EStructuralFeature
    def operation(operation_name_or_id)
      subclass_must_implement EClass
    end

    # @param operation [EOperation]
    # @return [Integer]
    def operation_id(operation)
      subclass_must_implement EClass
    end

    # @param operation [EOperation]
    # @return [Operation]
    def override(operation)
      subclass_must_implement EClass
    end
  end

  module EDataType
    include EClassifier
  end

  module EENum
    include EDataType
  end

  module EEnumLiteral
    include Enumerator
    include ENamedElement
  end

  module ETypedElement
    include ENamedElement
  end

  module ETypeParameter
    include ENamedElement
  end

  module EOperation
    include ETypedElement
  end

  module EParameter
    include ETypedElement
  end

  module EStructuralFeature
    include ETypedElement
  end

  module EAttribute
    include EStructuralFeature
  end

  module EReference
    include EStructuralFeature
  end
end