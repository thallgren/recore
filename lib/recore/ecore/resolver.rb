require 'recore/ecore/acceptor'

module ReCore::Ecore
  class Resolver
    PROXY_URI_PATTERN = /^([\w]+):(\w+)\s+(?:[^#]+)#\/\/(.+)?$/

    include TraversalAcceptor

    # @param *packages [ReCore::Ecore::Model::EPackage]
    def initialize(*packages)
      @package_stack = packages.clone
    end

    def accept_EClass(eclass, args)
      super
      st = eclass.super_types(true)
      eclass.super_types = st.map {|uri| resolve_uri(uri)} if !st.nil? && st.first.is_a?(String)
    end

    def accept_EGenericType(generic_type, args)
      super
      cf = generic_type.classifier
      generic_type.classifier = resolve_uri(cf) if cf.is_a?(String)
      tp = generic_type.type_parameter
      generic_type.type_parameter = resolve_uri(tp) if tp.is_a?(String)
    end

    def accept_ETypedElement(typed_element, args)
      super
      et = typed_element.e_type
      typed_element.e_type = resolve_uri(et) if et.is_a?(String)
    end

    def accept_EOperation(operation, args)
      super
      et = operation.exceptions(true)
      operation.exceptions = et.map {|e| resolve_uri(e)} if !et.nil? && et.first.is_a?(String)
    end

    def accept_EPackage(package, args)
      @package_stack.push(package)
      super
      fi = package.factory_instance
      package.factory_instance = resolve_uri(fi) if fi.is_a?(String)
      @package_stack.pop
    end

    def accept_EReference(reference, args)
      super
      os = reference.opposite
      reference.opposite = resolve_uri(os) if os.is_a?(String)
      ks = reference.keys(true)
      reference.keys = ks.map { |k| resolve_uri(k) } if !ks.nil? && ks.first.is_a?(String)
    end

    def current_package
      @package_stack.last
    end

    # @param eclassifier [ReCore::Ecore::Model::EClassifier]
    # @param path [Array<String>]
    # @return [ENamedElement]
    def resolve_path(eclassifier, path)
      result = path.reduce(self) {|memo, segment| break nil if memo.nil?; memo.resolve_segment(eclassifier, segment)}
      raise ArgumentError "Unable to resolve path #{path.join('/')}" if result.nil?
      result
    end

    # @param eclassifier [ReCore::Ecore::Model::EClassifier]
    # @param segment [String]
    # @return [ENamedElement]
    def resolve_segment(eclassifier, segment)
      return nil unless eclassifier.is_a?(ReCore::Ecore::Model::EClass)
      found = eclassifier.attributes.find {|a| a.name == segment}
      found = eclassifier.references.find {|r| r.name == segment} if found.nil?
      found = eclassifier.operations.each {|o| o.name == segment} if found.nil?
      found
    end

    def resolve_local(package, classifier_type, classifier_name)
      case classifier_type
      when 'EClass'
        classifier = package.classes[classifier_name]
      when 'EDataType'
        classifier = package.data_types[classifier_name]
      else
        classifier = nil
      end
      raise ArgumentError, "Unable to find #{classifier_type} '#{classifier_name}' in package #{package.name}" if classifier.nil?
      classifier
    end

    def resolve_uri(uri)
      found = nil
      if uri.start_with?('#//')
        # Package local resolution or classifier
        path = uri[3..-1].split('/')
        classifier_name = path[0]
        package = current_package
        found = package.classes[classifier_name]
        if found.nil?
          found = package.data_types[classifier_name] if found.nil?
        else
          found = resolve_path(found, path.drop(1)) if path.size > 1
        end
      elsif uri =~ PROXY_URI_PATTERN
        ns_prefix = $1
        classifier_type = $2
        classifier_name = $3
        package = @package_stack.find { |p| p.ns_prefix == ns_prefix }
        raise ArgumentError, "No EPackage for namespace prefix #{ns_prefix}" if package.nil?
        found = resolve_local(package, classifier_type, classifier_name)
      end
      raise ArgumentError, "Unable to resolve uri #{uri}" if found.nil?
      found
    end
  end
end