require 'recore/ecore/acceptor'

module ReCore::Ecore
  class Resolver
    include TraversalAcceptor

    def accept_default(e, args)
      e.resolve(args)
    end
  end
end