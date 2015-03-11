require 'recore/ecore/acceptor'
require 'recore/ecore/type_mapper'

module ReCore::Ecore::Generator

  NEWLINE = "\n".freeze

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
      bld.puts
      bld << 'module ' << package.name.capitalize << '::Impl'
      package.classes.values.sort.each { |c| accept(c, bld) }
      bld.puts('end')
    end

    # @param clazz [ReCore::Ecore::Model::EClass]
    # @param bld [IO]
    def accept_EClass(clazz, bld)
      bld.puts
      bld << '  class '
      bld << clazz.name
      bld << 'Impl'
      if clazz.super_types.empty?
        bld << ' < ' << @default_super_type unless @default_super_type.nil?
      else
        bld << ' < ' << clazz.super_types.first << 'Impl'
      end
      bld.puts
      bld << '    include ' << clazz.name
      bld.puts
      clazz.attributes.each { |a| accept(a, bld) }
      clazz.references.each { |r| accept(r, bld) }
      bld.puts('  end')
    end

    # @param feature [ReCore::Ecore::Model::EStructuralFeature]
    # @param args [Array<Object>]
    def accept_EStructuralFeature(feature, bld)
      uname = @interface.attribute_name(feature.name)
      type_name = @interface.type_name(feature)

      # Getter
      bld.puts
      bld << '    # @return [' << type_name << ']'
      bld.puts
      bld << '    def ' << uname
      bld << '?' if type_name == 'Boolean'
      bld.puts
      bld << '      @' << uname
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
      bld.puts
      bld.puts('    end')

      # Setter
      bld.puts
      bld << '    # @param ' << uname << ' [' << type_name
      bld.puts(']')
      bld << '    def ' << uname << '=' << '(' << uname
      bld.puts(')')
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
      bld.puts
      bld.puts('    end')

      if feature.upper_bound < 0
        # Adder
        sname = uname
        sname = sname[0..-2] if sname.end_with?('s')
        bld.puts
        bld << '    # @param ' << sname << ' [' << type_name[6, -2] << ']'
        bld.puts
        bld << '    def add_' << sname << '(' << sname << ')'
        bld.puts
        bld << '      @' << uname << ' ||= EMPTY_ARRAY'
        bld.puts
        bld << '      @' << uname << ' << ' << sname
        bld.puts
        bld.puts('    end')
      end

      def create_from_string_call(feature, string, bld)
        # TODO: Return factory method to create instance from string
      end
    end
  end
end

