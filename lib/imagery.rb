require 'escape'
require 'fileutils'

module Imagery
  VERSION = "0.0.4"
  
  autoload :Model,   "imagery/model"
  autoload :Faking,  "imagery/faking"
  autoload :S3,      "imagery/s3"
  autoload :Missing, "imagery/missing"
  autoload :Test,    "imagery/test"
  
  # Syntactic sugar for Imagery::Model::new
  # @see Imagery::Model#initialize for details
  def new(*args, &blk)
    Model.new(*args, &blk)
  end
  module_function :new
end
