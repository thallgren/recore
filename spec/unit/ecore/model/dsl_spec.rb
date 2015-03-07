require 'spec_helper'

module ReCore::Ecore::Model
  RSpec.describe DSL do
    describe '#add_class' do
      it 'can add class using dsl block' do
        dsl = DSL.new
        dsl.instance_eval do
          package('Foo', 'http://foo.bar.com/foo') do
            add_class('FirstClass') do
              abstract
              attributes do
                one 'service', 'EInteger'
              end
              containments do
                many 'users', 'User', 'User/firstClass'
              end
            end
            add_class('User') do
              attributes do
                one 'name', 'EString', true
                one 'email', 'EString', true
              end
              containments do
                one 'firstClass', 'FirstClass', 'FirstClass/users' do
                end
              end
            end
          end
        end
        dsl.resolve
      end
    end
  end
end
