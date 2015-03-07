require 'recore/ecore/model/acceptor'
require 'recore/ecore/type_mapper'

module ReCore::Ecore::Generator

  NEWLINE = "\n".freeze

  class ModelString
    include ReCore::Ecore::Model::Acceptor

    # @param clazz [ReCore::Ecore::Model::EClass]
    # @param bld [IO]
    def accept_EClass(clazz, bld)
      bld << 'Class[' << clazz.name << ']'
      supers = clazz.super_types
      bld << '<' << '[' << supers.map { |s| s.name }.join(',') << ']' unless supers.empty?
      options_start = bld.pos
      bld << ' ('
      bld << 'abstract,' if clazz.abstract?
      bld << 'interface,' if clazz.interface?
      # @TODO: generic_super_types
      if options_start == bld.pos - 2
        bld.pos = options_start
      else
        bld.pos = bld.pos - 1
        bld << ')'
      end
    end

    # @param feature [ReCore::Ecore::Model::EStructuralFeature]
    # @param bld [IO]
    def bounds(feature, bld)
      bld << 'bounds=[' << feature.lower_bound << ',' << feature.upper_bound << '],'
    end

    # @param feature [ReCore::Ecore::Model::EStructuralFeature]
    # @param bld [IO]
    def accept_EStructuralFeature(feature, bld)
      bld << 'unchangeable,' unless feature.changeable?
      bld << 'derived,' if feature.derived?
      bld << 'transient,' if feature.transient?
      bld << 'unsettable,' if feature.unsettable?
      bld << 'volatile,' if feature.volatile?
      bld << "default_value_literal='" << feature.default_value_literal << "'," unless feature.default_value_literal.nil?
      bld.pos = bld.pos - 1
      bld << ')'
    end

    # @param attribute [ReCore::Ecore::Model::EAttribute]
    # @param bld [IO]
    def accept_EAttribute(attribute, bld)
      bld << 'Attribute[' << attribute.e_type.name << '] ('
      bounds(attribute, bld)
      bld << 'id,' if attribute.id?
      super
    end

    # @param reference [ReCore::Ecore::Model::EReference]
    # @param bld [IO]
    def accept_EReference(reference, bld)
      bld << 'Reference[' << reference.e_type.name << '] ('
      bounds(reference, bld)
      o = reference.opposite
      bld << 'opposite=' << o.e_type.name << '/' << o.name << ',' unless o.nil?
      bld << 'containment,' if reference.containment?
      bld << 'lazy_proxies,' unless reference.resolve_proxies?
      super
    end
  end

  class Interface
    include ReCore::Ecore::Model::Acceptor

    def initialize
      @type_mapper = ReCore::Ecore::TypeMapper::ECORE_MAPPER
      @attribute_name_map = {}
      @method_name_map = {}
      @model_string = ModelString.new
    end

    # @param package [ReCore::Ecore::Model::EPackage]
    # @param bld [IO]
    def accept_EPackage(package, bld)
      bld << 'module '
      bld << package.name.capitalize
      package.classes.values.sort.each { |c| accept(c, bld) }
      bld.puts('end')
    end

    # @param clazz [ReCore::Ecore::Model::EClass]
    # @param bld [IO]
    def accept_EClass(clazz, bld)
      bld.puts
      bld << '  # @model '
      @model_string.accept(clazz, bld)
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
      prop_names = {}
      args = [prop_names, bld]
      clazz.attributes.each { |a| accept(a, args) }
      clazz.references.each { |r| accept(r, args) }
      clazz.operations.each { |o| accept(o, args) }
      bld.puts('  end')
    end

    # @param operation [ReCore::Ecore::Model::EOperation]
    # @param args [Array<Object>]
    def accept_EOperation(operation, args)
      prop_names = args[0]
      type_name = @type_mapper.map_type(operation)
      mname = method_name(operation.name)
      if setter?(operation)
        mname = mname + '='
      elsif type_name == 'Boolean'
        mname = mname + '?'
      end
      return if prop_names.include?(mname)

      prop_names[mname] = true
      bld = args[1]
      bld.puts

      params = operation.parameters
      uscore_params = []
      params.each do |param|
        param_name = underscore(param.name)
        uscore_params << param_name
        bld << '    # @param '
        bld << param_name
        bld << ' ['
        bld << @type_mapper.map_type(param)
        bld.puts(']')
      end

      bld << '    # @return ['
      bld << type_name
      bld.puts(']')

      bld << '    def '
      bld << mname
      if params.empty?
        bld.puts
      else
        uscore_params.reduce('(') { |m, p| bld << m; bld << p; ', ' }
        bld.puts(')')
      end
      bld << '      subclass_must_implement '
      bld.puts(operation.containing_class.name)
      bld.puts('    end')
    end

    # @param feature [ReCore::Ecore::Model::EStructuralFeature]
    # @param args [Array<Object>]
    def accept_EStructuralFeature(feature, args)
      prop_names = args[0]
      type_name = @type_mapper.map_type(feature)
      uname = attribute_name(feature.name)
      if type_name == 'Boolean'
        uname = uname + '?'
      end
      prop_names[uname] = true

      bld = args[1]
      bld.puts
      bld << '    # @model '
      @model_string.accept(feature, bld)
      bld.puts
      bld << '    # @return ['
      bld << type_name
      bld.puts(']')
      bld << '    def '
      bld << uname
      bld.puts
      bld << '      subclass_must_implement '
      bld.puts(feature.containing_class.name)
      bld.puts('    end')
    end

    def setter?(operation)
      !!operation.name =~ /set[A-Z]/ && operation.parameters.size == 1
    end

    def method_name(name)
      mname = @method_name_map[name]
      if mname.nil?
        mname = underscore(name)
        if mname.start_with?('get_')
          mname = mname[4..-1]
        elsif mname.start_with?('set_')
          mname = mname[4..-1]
        elsif mname.start_with?('is_')
          mname = mname[3..-1]
        end
        @method_name_map[name] = mname
      end
      mname
    end

    def attribute_name(name)
      aname = @attribute_name_map[name]
      if aname.nil?
        aname = underscore(name)
        @attribute_name_map[name] = aname
      end
      aname
    end

    def underscore(name)
      # translate all 'X' to '_x'
      uscore = name.gsub(/[A-Z]/) { |m| '_' + m.downcase }

      # translate ugly names like i_d, e_i_d or ns_u_r_i
      uscore.sub!(/(?:^|_)[a-z0-9](?:_[a-z0-9])+(?:$|_)/) { |m| m.gsub!(/([a-z0-9])_/, '\1')}
      uscore
    end
  end
end
