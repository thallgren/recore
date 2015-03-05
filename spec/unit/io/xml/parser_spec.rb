require 'spec_helper'

module ReCore::IO::XML
  RSpec.describe Parser do
    describe '#parse' do
      it 'can parse ECore.ecore successfully' do
        handler = ReCore::Ecore::Parser::ECoreHandler.new
        parser = Parser.new(handler)
        File.open(File.join(ReCore::MODULE_DIR, 'Ecore.ecore')) do |file|
          parser.parse(file)
        end
        result = handler.result
        expect(result).to be_a(ReCore::Ecore::Parser::EPackage)
      end
    end
  end
end
