require 'spec_helper'

module ReCore::Ecore::Model
  RSpec.describe EObject do
    describe '#subclass_must_implement' do
      it 'will raise exceptions on undefined methods' do
        class BogusECoreImpl
          include EObject
        end
        expect { BogusECoreImpl.new.eClass }.to raise_error(NoMethodError, /class ReCore::ECore::BogusECoreImpl must implement ECore#e_class/)
      end
    end
  end
end
