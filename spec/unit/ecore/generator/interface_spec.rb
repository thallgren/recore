require 'spec_helper'

module ReCore::Ecore::Generator
  describe 'Interface generator' do
    it 'can generate ruby interfaces' do
      resource = []
      dsl = ReCore::Ecore::DSL.new(resource) do
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
            references do
              one 'one_a', 'A', 'many_b' do
              end
            end
          end
        end
      end
      package = resource[0]
      expect(package).to be_a(ReCore::Ecore::Model::EPackage)
      classes = package.classes
      expect(classes).to be_a(Hash)

      ReCore::Ecore::Generator::Interface.new.accept(package, $>)
    end
  end
end

