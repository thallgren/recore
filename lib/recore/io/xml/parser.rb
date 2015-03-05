require 'nokogiri'

module ReCore::IO::XML
  module Handler
    include ReCore::Util

    def start_element(tag, attributes)
      send(tag, attributes)
    end

    def end_element(tag)
      subclass_must_implement Handler
    end

    def namespace
      subclass_must_implement Handler
    end
  end

  class Parser < Nokogiri::XML::SAX::Document
    NO_ATTRS = {}.freeze
    COLON = ':'

    # @return [Handler] The handler for the namespace
    def namespace_handler(prefix)
      @namespace_handlers[@namespaces[prefix]]
    end

    def start_element_namespace(tag, attributes, prefix, uri, namespaces)
      namespaces.each{|n| @namespaces[n[0]] = n[1]}
      if attributes.empty?
        attrs = NO_ATTRS
      else
        attrs = {}
        attributes.each { |a| name = a.prefix ? a.prefix+COLON+a.localname : a.localname; attrs[name] = a.value}
      end
      if prefix.nil?
        prefix = @prefix_stack.last
      else
        @prefix_stack.push(prefix) unless @prefix_stack.last == prefix
      end
      namespace_handler(prefix).start_element(tag, attrs)
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
      handlers.each { |h| @namespace_handlers[h.namespace] = h }
    end
  end
end

