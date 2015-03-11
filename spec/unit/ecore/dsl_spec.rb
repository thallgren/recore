require 'spec_helper'

module ReCore::Ecore
  RSpec.describe DSL do
    it 'can add class using dsl block' do
      handler = ReCore::Ecore::Parser::Handler.new
      parser = ReCore::IO::XML::Parser.new(handler)
      File.open(File.join(ReCore::MODULE_DIR, 'Ecore.ecore')) do |file|
        parser.parse(file)
      end
      ecore_package = handler.result
      ReCore::Ecore::Resolver.new.accept(ecore_package, nil)

      resource = []
      ReCore::Ecore::DSL.new(resource) do
        package('Foo', 'http://foo.bar.com/foo') do
          add_class('A') do
            abstract
            attributes do
              one 'int_attr', Integer
            end
            containments do
              many 'many_bs', 'B', 'one_a'
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
      ReCore::Ecore::Resolver.new(ecore_package).accept(package, nil)
      classes = package.classes
      expect(classes).to be_a(Hash)

      interface_generator =  ReCore::Ecore::Generator::Interface.new
      interface_generator.accept(package, $>)

      impl_generator =  ReCore::Ecore::Generator::Impl.new(interface_generator)
      impl_generator.accept(package, $>)
    end
  end
end
