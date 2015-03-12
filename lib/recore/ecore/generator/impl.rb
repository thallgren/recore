require 'recore/ecore/acceptor'
require 'recore/ecore/type_mapper'

module ReCore::Ecore::Generator
  class Impl
    include ReCore::Ecore::Acceptor

    # @param interface [Interface]
    def initialize(interface)
      @interface = interface
      @default_super_type = nil
    end

    # @param package [ReCore::Ecore::Model::EPackage]
    # @param bld [IO]
    def accept_EPackage(package, bld)
      bld << "\nmodule " << package.name.capitalize << '::Impl'
      package.classes.values.sort.each { |c| accept(c, bld) }
      bld << "end\n"
    end

    # @param clazz [ReCore::Ecore::Model::EClass]
    # @param bld [IO]
    def accept_EClass(clazz, bld)
      bld << "\n  class " << clazz.name << 'Impl'
      if clazz.super_types.empty?
        bld << ' < ' << @default_super_type unless @default_super_type.nil?
      else
        bld << ' < ' << clazz.super_types.first.name << 'Impl'
      end
      bld << "\n    include " << clazz.name << "\n"
      clazz.attributes.each { |a| accept(a, bld) }
      clazz.references.each { |r| accept(r, bld) }
      bld << "  end\n"
    end

    # @param feature [ReCore::Ecore::Model::EStructuralFeature]
    # @param args [Array<Object>]
    def accept_EStructuralFeature(feature, bld)
      uname = @interface.attribute_name(feature.name)
      type_name = @interface.type_name(feature)

      # Getter
      bld << "\n    # @return [" << type_name << "]\n"
      bld << '    def ' << uname
      bld << '?' if type_name == 'Boolean'
      bld << "\n      @" << uname
      dflt = feature.default_value_literal
      if feature.upper_bound < 0
        bld << ' || EMPTY_ARRAY'
      elsif type_name == 'Boolean'
        bld << '.nil? ? ' << (dflt || 'false') << ' : @' << uname
      elsif type_name == 'Integer'
        bld << ' || ' << (dflt || '0')
      elsif type_name == 'Float'
        bld << ' || ' << (dflt || '0.0')
      elsif type_name == 'String'
        bld << " || '#{dflt}'" unless dflt.nil?
      else
        unless dflt.nil?
          bld << ' || '
          create_from_string_call(feature, dflt, bld)
        end
      end
      bld << "\n    end\n"

      # Setter
      bld << "\n    # @param " << uname << ' [' << type_name << "]\n"
      bld << '    def ' << uname << '=' << '(' << uname << ")\n"
      bld << '      @' << uname << ' = '
      if feature.upper_bound < 0
        bld << 'array_or_nil(' << uname << ')'
      elsif type_name == 'Boolean'
        bld << 'bool_or_nil(' << uname << ')'
      elsif type_name == 'Integer'
        bld << 'int_or_nil(' << uname << ')'
      elsif type_name == 'Float'
        bld << 'float_or_nil(' << uname << ')'
      else
        bld << uname
      end
      bld << "\n    end\n"

      if feature.upper_bound < 0
        # Adder
        sname = uname
        sname = sname[0..-2] if sname.end_with?('s')
        bld << "\n    # @param " << sname << ' [' << type_name[6, -2] << "]\n"
        bld << '    def add_' << sname << '(' << sname << ")\n"
        bld << '      @' << uname << " ||= EMPTY_ARRAY\n"
        bld << '      @' << uname << ' << ' << sname
        bld << "\n    end\n"
      end

      def create_from_string_call(feature, string, bld)
        # TODO: Return factory method to create instance from string
      end
    end
  end
end

