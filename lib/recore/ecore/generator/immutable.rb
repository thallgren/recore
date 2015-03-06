require 'recore/ecore/model/acceptor'
require 'recore/ecore/type_mapper'

module ReCore::Ecore::Generator

  NEWLINE = "\n".freeze

class Immutable
  include ReCore::Ecore::Model::Acceptor

  def initialize
    @type_mapper = ReCore::Ecore::TypeMapper::ECORE_MAPPER
  end

  # @param package [ReCore::Ecore::Model::EPackage]
  # @param bld [StringIO]
  def accept_EPackage(package, bld)
    bld << 'module '
    bld << package.name.capitalize
    package.classes.values.sort.each { |c| accept(c, bld) }
    bld.puts('end')
  end

  # @param clazz [ReCore::Ecore::Model::EClass]
  def accept_EClass(clazz, bld)
    bld.puts
    bld << '  module '
    bld.puts(clazz.name)
    if clazz.super_types.empty?
      bld.puts('    include ReCore::Util')
    else
      clazz.super_types.each do |super_type|
        bld << '    include '
        bld.puts(super_type.name)
      end
    end
    clazz.attributes.each { |a| accept(a, bld) }
    clazz.references.each { |r| accept(r, bld) }
    bld.puts('  end')
  end

  # @param feature [ReCore::Ecore::Model::EStructuralFeature]
  def accept_EStructuralFeature(feature, bld)
    uname = underscore(feature.name)
    bld.puts
    bld << '    # @return ['
    type_name = @type_mapper.map_type(feature)
    bld << type_name
    bld.puts(']')
    bld << '    def '
    bld << uname
    bld << '?' if type_name == 'Boolean'
    bld.puts
    bld << '      subclass_must_implement '
    bld.puts(feature.containing_class.name)
    bld.puts('    end')
  end

  def map_type(type_name)
    @type_to_ruby_map[type_name] || type_name
  end

  def underscore(name)
    name.gsub(/([A-Z])/) {'_' + $1.downcase}
  end
end
end
