require 'escape'
require 'fileutils'

module Imagery
  VERSION = "0.0.1"
  
  autoload :Model,  "imagery/model"
  autoload :Faking, "imagery/faking"
  autoload :S3,     "imagery/s3"

  def new(*args, &blk)
    Model.new(*args, &blk)
  end
  module_function :new
  
  def faked(&blk)
    Model.faked(&blk)
  end
  module_function :faked

  def real(&blk)
    Model.real(&blk) 
  end
  module_function :real
end
