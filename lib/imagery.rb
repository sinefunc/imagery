require 'escape'
require 'fileutils'

module Imagery
  VERSION = "0.0.1"
  
  autoload :Model,  "imagery/model"
  autoload :Faking, "imagery/faking"
  autoload :S3,     "imagery/s3"
  autoload :Test,   "imagery/test"
  
  # Syntactic sugar for Imagery::Model::new
  # @see Imagery::Model#initialize for details
  def new(*args, &blk)
    Model.new(*args, &blk)
  end
  module_function :new
  
  # Syntactic sugar for Imagery::Model::faked
  # @see Imagery::Model::faked for details
  def faked(&blk)
    Model.faked(&blk)
  end
  module_function :faked

  # Syntactic sugar for Imagery::Model::real
  # @see Imagery::Model::real for details
  def real(&blk)
    Model.real(&blk) 
  end
  module_function :real
end
