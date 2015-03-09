require 'nokogiri'

module ReCore::IO::XML

  class AttributeKey
    # @param ns_uri [String]
    # @param name [String]
    def initialize(ns_uri, name, method)
      @ns_uri = ns_uri
      @name = name
      @method = method
    end

    # @param attribute Nokogiri::XML::SAX::Parser::Attribute
    def key_for?(attribute)
      uri = attribute.uri
      (uri.nil? || uri == @ns_uri) && attribute.localname == @name
    end

    def assign(attribute, instance)
      instance.send(@method, attribute.value)
    end
  end

  module Handler
    XSI_NAMESPACE = 'http://www.w3.org/2001/XMLSchema-instance'
    XSI_TYPE_KEY = AttributeKey.new(XSI_NAMESPACE, 'type', nil)

    include ReCore::InterfaceSupport

    def start_element(tag, attributes)
      send(tag, attributes)
    end

    def end_element(tag)
      subclass_must_implement Handler
    end

    def namespace
      subclass_must_implement Handler
    end

    def parser=(parser)
      subclass_must_implement Handler
    end

    def keys(name_to_method_map)
      ns_uri = namespace
      result = {}
      name_to_method_map.each_pair { |name, method| result[name] = AttributeKey.new(ns_uri, name, method) }
      result
    end

    def values(attributes, *keys)
      result = Array.new(keys.size)
      attributes.each do |attribute|
        next if attribute.uri == XSI_NAMESPACE
        index = keys.index { |key| key.key_for?(attribute) }
        raise ParseError, "Unexpected attribute '#{attribute.localname}'" if index.nil?
        result[index] = attribute.value
      end
      result
    end

    def assign_attribute_values(instance, keys, attributes)
      attributes.each do |attribute|
        next if attribute.uri == XSI_NAMESPACE
        key = keys[attribute.localname]
        raise ParseError, "Unexpected attribute '#{attribute.localname}'" if key.nil?
        key.assign(attribute, instance)
      end
    end

    def xsi_type(attributes)
      type_attr = attributes.find { |a| XSI_TYPE_KEY.key_for?(a) }
      raise ParseError 'Unable to find xsi:type' if type_attr.nil?
      xt = type_attr.value
      xt = xt[6..-1] if xt.start_with?('ecore:')
      xt
    end
  end

  class Parser < Nokogiri::XML::SAX::Document
    NO_ATTRS = [].freeze
    COLON = ':'

    # @return [Handler] The handler for the namespace
    def namespace_handler(prefix)
      @namespace_handlers[@namespaces[prefix]]
    end

    def start_element_namespace(tag, attributes, prefix, uri, namespaces)
      namespaces.each{|n| @namespaces[n[0]] = n[1]}
      if prefix.nil?
        prefix = @prefix_stack.last
      else
        @prefix_stack.push(prefix) unless @prefix_stack.last == prefix
      end
      namespace_handler(prefix).start_element(tag, attributes)
    end

    def end_element_namespace(tag, prefix, uri)
      if prefix.nil?
        prefix = @prefix_stack.last
      else
        @prefix_stack.pop() if @prefix_stack.last == prefix
      end
      namespace_handler(prefix).end_element(tag)
    end

    def parse(file)
      @namespaces = {}
      @prefix_stack = []
      Nokogiri::XML::SAX::Parser.new(self).parse(file)
    end

    def initialize(*handlers)
      @namespace_handlers = {}
      handlers.each do |handler|
        @namespace_handlers[handler.namespace] = handler
        handler.parser = self
      end
    end
  end
end

