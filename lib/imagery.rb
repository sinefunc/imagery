require 'escape'
require 'fileutils'

module Imagery
  VERSION = "0.0.6"
  
  autoload :Model,   "imagery/model"
  autoload :Faking,  "imagery/faking"
  autoload :S3,      "imagery/s3"
  autoload :Missing, "imagery/missing"
  autoload :Test,    "imagery/test"
  
  # Syntactic sugar for Imagery::Model::new
  # @yield Imagery::Model
  # @see Imagery::Model#initialize for details
  def new(*args)
    Model.new(*args).tap { |model| yield model  if block_given? }
  end
  module_function :new
end
