require 'spec_helper'

module ReCore::Ecore::Model
  RSpec.describe DSL do
    it 'can add class using dsl block' do
      dsl = DSL.new
      dsl.instance_eval do
        package('Foo', 'http://foo.bar.com/foo') do
          add_class('A') do
            abstract
            attributes do
              one 'int_attr', Integer
            end
            containments do
              many 'many_b', 'B', 'one_a'
            end
          end
          add_class('B') do
            super_class 'A'
            attributes do
              one 'string_attr', String, true
              one 'long_attr', 'ELong', true
            end
            containments do
              one 'one_a', 'A', 'many_b' do
              end
            end
          end
        end
      end
      package = dsl.resolve
      expect(package).to be_a(EPackage)
      classes = package.classes
      expect(classes).to be_a(Hash)

      bld = StringIO.new
      ReCore::Ecore::Generator::Interface.new.accept(package, bld)
      puts bld.string

    end
  end
end
