module ReCore::Ecore
class TypeMapper

  def initialize
    @type_map = {}
  end

  # @param feature [ReCore::Ecore::Model::EStructuralFeature]
  # @return [String]
  def map_type(feature)
    many = feature.upper_bound < 0
    type = feature.e_type
    type_name = type.nil? ? 'Object' : type.name
    if many && type_name == 'EStringToStringMapEntry'
      type_name = 'Map<String,String>'
    else
      type_name = map_type_name(type.name) if type.is_a?(ReCore::Ecore::Model::EDataType)
      type_name = "Array<#{type_name}>" if many
    end
    type_name
  end

  def map_type_name(type_name)
    @type_map[type_name] || 'Object'
  end

  # @param type_name [String]
  # @param ruby_name [String]
  def register_type_mapping(type_name, ruby_name)
    @type_map[type_name] = ruby_name
  end

  ecore_mapper = TypeMapper.new
  ecore_mapper.register_type_mapping('EChar', 'String')
  ecore_mapper.register_type_mapping('EString', 'String')
  ecore_mapper.register_type_mapping('Object', 'Object')
  ecore_mapper.register_type_mapping('EJavaObject', 'Object')
  ecore_mapper.register_type_mapping('EInt', 'Integer')
  ecore_mapper.register_type_mapping('EIntegerObject', 'Integer')
  ecore_mapper.register_type_mapping('ELong', 'Integer')
  ecore_mapper.register_type_mapping('ELongObject', 'Integer')
  ecore_mapper.register_type_mapping('EShort', 'Integer')
  ecore_mapper.register_type_mapping('EShortObject', 'Integer')
  ecore_mapper.register_type_mapping('EBoolean', 'Boolean')

  ECORE_MAPPER = ecore_mapper
end
end
