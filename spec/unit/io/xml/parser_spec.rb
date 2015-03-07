require 'spec_helper'

module ReCore::IO::XML
  RSpec.describe Parser do
    describe '#parse' do
      it 'can parse ECore.ecore successfully' do
        handler = ReCore::Ecore::Model::Handler.new
        parser = Parser.new(handler)
        File.open(File.join(ReCore::MODULE_DIR, 'Ecore.ecore')) do |file|
          parser.parse(file)
        end
        result = handler.result
        expect(result).to be_a(ReCore::Ecore::Model::EPackage)

        bld = StringIO.new
        ReCore::Ecore::Generator::Interface.new.accept(result, bld)
        puts bld.string
      end
    end
  end
end
