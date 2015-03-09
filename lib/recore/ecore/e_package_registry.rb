require 'recore/ecore/model'

class ReCore::Ecore::EPackageRegistry
  def initialize
    @packages = {}
  end

  def <<(package)
    @packages[package.ns_uri] = package
  end
end