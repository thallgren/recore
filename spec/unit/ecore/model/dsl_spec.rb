require 'spec_helper'

module ReCore::Ecore::Model
  RSpec.describe EPackage do
    describe '#add_class' do
      it 'can add class using dsl block' do
        package = EPackage.new
        package.instance_eval do
          ns_uri 'http://foo.bar.com/foo'
          ns_prefix 'foo'
          factory_instance_uri '#//FooFactory'
          add_class do
            add_attribute do
              name = 'first'
            end
          end
        end
      end
    end
  end
end
