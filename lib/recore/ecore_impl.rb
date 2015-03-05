require 'recore/ecore'

module ReCore::ECore
  class EObjectImpl
    include EObject

    attr_accessor :e_class
    attr_accessor :e_resource
    attr_accessor :e_container

    # @return [Array<EObject>] The contained objects
    def e_contents
      @e_contents ||= []
    end

    # @return [Array<EObject>] All contained objects, direct and indirect
    def e_all_contents
      e_contents + e_contents.map { |eo| eo.e_all_contents }.flatten
    end

    # @return [Array<EObject>] The contained objects
    def e_contents=(e_contents)
      @e_contents = e_contents
    end
  end
end