require 'rspec'
require 'recore'
require 'pry'

# So everyone else doesn't have to include this base constant.
module ReCore
  FIXTURE_DIR = File.join(dir = File.expand_path(File.dirname(__FILE__)), 'unit', 'fixtures') unless defined?(MODULE_DIR)
  MODULE_DIR = File.join(dir = File.expand_path(File.dirname(File.dirname(__FILE__))), 'model') unless defined?(MODULE_DIR)
end
