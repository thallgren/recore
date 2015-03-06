require 'recore/ecore/model/model'

module ReCore::Ecore::Model

  EPackage.new.instance_eval do
    ns_uri = 'http://foo.bar.com/foo'
    ns_prefix = 'foo'
    factory_instance_uri = '#//FooFactory'

    e_class do

    end
  end
end