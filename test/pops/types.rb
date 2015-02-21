module Puppet
end
module Puppet::Pops
end

module Puppet::Pops::Types

  module PAnyType
    def eclass
      self.class.ancestors.each { |x| return x if !x.is_a?(Class) && x < PAnyType }
    end
  end

  module PDataType
    include PAnyType
  end

  module PScalarType
    include PDataType
  end

  module PIntegerType
    include PScalarType
  end

  module PCollectionType
    include PDataType
  end

  module PArrayType
    include PCollectionType
  end






  class PAnyType_impl
    include PAnyType
  end

  class PIntegerType_impl
    include PIntegerType

    attr_reader :from
    attr_reader :to

    def initialize(from, to)
      @from = from
      @to = to
    end
  end

  class PIntegerType_iwrap
    include PIntegerType

    def initialize(val)
      @val = val
    end

    def from
      @val
    end

    alias :to :from
  end

  class PArrayType_impl
    include PArrayType

    attr_reader :size_type
    attr_reader :element_type

    def initialize(size_type, element_type)
      @size_type = size_type
      @element_type = element_type
    end
  end

  class PArrayType_dataimpl < PArrayType_impl
    include PDataType
  end

  def self.create_PAnyType
    PAnyType_impl.new
  end

  def self.iwrap_PIntegerType(val)
    PIntegerType_iwrap.new(val)
  end

  def self.create_PIntegerType(from, to=Float::INFINITY)
    PIntegerType_impl.new(from, to)
  end

  def self.create_PArrayType(size_type, element_type)
    element_type.is_a?(PDataType) ? PArrayType_dataimpl.new(size_type, element_type) : PArrayType_impl.new(size_type, element_type)
  end
end

Types = Puppet::Pops::Types
int_array = Types.create_PArrayType(Types.iwrap_PIntegerType(0), Types.create_PIntegerType(0))
puts int_array.is_a?(Types::PAnyType)
puts int_array.is_a?(Types::PDataType)
puts int_array.is_a?(Types::PArrayType)
puts int_array.eclass
puts int_array.element_type.eclass
puts int_array.size_type.is_a?(Types::PIntegerType)
puts int_array.size_type.from
puts int_array.size_type.to
