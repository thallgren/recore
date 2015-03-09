module ReCore::Ecore
class TypeMapper
  ECORE_DATA_TYPE_URI_PREFIX = "#{NS_PREFIX}:EDataType #{NS_URI}#//"
  ECORE_DATA_TYPE_URI_PATTERN = Regexp.compile("#{Regexp.escape(ECORE_DATA_TYPE_URI_PREFIX)}(\\w+)$")

  def initialize
    @ecore_to_ruby = {}
    @ruby_to_ecore = {}
  end

  # @param typed_element [ReCore::Ecore::Model::ETypedElement]
  # @return [String]
  def map_type(typed_element)
    many = typed_element.upper_bound < 0
    type = typed_element.e_type
    type_name = type.nil? ? 'Object' : type.name
    if many && type_name == 'EStringToStringMapEntry'
      type_name = 'Map<String,String>'
    else
      type_name = ecore_to_ruby(type.name) if type.is_a?(ReCore::Ecore::Model::EDataType)
      type_name = "Array<#{type_name}>" if many
    end
    type_name
  end

  # @param ecore_name [String]
  # @return [String]
  def ecore_to_ruby(ecore_name)
    ruby_name = @ecore_to_ruby[ecore_name]
    raise ArgumentError, "Unknown ECore data type '#{ecore_name}'" if ruby_name.nil?
    ruby_name
  end

  # @param ecore_uri [String]
  # @return [String]
  def ecore__uri_to_ruby(ecore_uri)
    raise ArgumentError, "Not an ECore data type URI '#{ecore_uri}'" unless ecore_uri =~ ECORE_DATA_TYPE_URI_PATTERN
    ecore_to_ruby($1)
  end

  # @param ruby_name_or_class [Class|String]
  # @return [String]
  def ruby_to_ecore(ruby_name_or_class)
    ruby_name = ruby_name_or_class.is_a?(Class) ? ruby_name_or_class.name : ruby_name_or_class
    ecore_name = @ruby_to_ecore[ruby_name]
    raise ArgumentError, "Ecore type unknown for ruby class '#{ruby_name}'" if ecore_name.nil?
    ecore_name
  end

  # @param ruby_name_or_class [Class|String]
  # @return [String]
  def ruby_to_ecore_uri(ruby_name_or_class)
    ECORE_DATA_TYPE_URI_PREFIX + ruby_to_ecore(ruby_name_or_class)
  end

  # @param *ecore_names [String]
  # @param ruby_name [String]
  def register_type_mapping(ruby_name, *ecore_names)
    ecore_names.each { |ecore_name| @ecore_to_ruby[ecore_name] = ruby_name }
    @ruby_to_ecore[ruby_name] = ecore_names[0]
  end

  ecore_mapper = TypeMapper.new
  ecore_mapper.register_type_mapping('String', 'EString', 'EChar')
  ecore_mapper.register_type_mapping('Object', 'EJavaObject')
  ecore_mapper.register_type_mapping('Integer', 'EInt', 'ELong', 'EShort', 'EIntegerObject', 'ELongObject', 'EShortObject')
  ecore_mapper.register_type_mapping('Boolean', 'EBoolean')
  ecore_mapper.register_type_mapping('EEnumLiteral', 'Enumerator')
  ecore_mapper.register_type_mapping('Enumerator', 'EEnumerator')
  ecore_mapper.register_type_mapping('Resource', 'EResource')

  ECORE_MAPPER = ecore_mapper
end
end
