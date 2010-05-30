module Imagery
  module Test
    def self.included(base)
      Imagery::Model.send :include, Imagery::Faking
      Imagery::Model.mode = :fake
    end

  protected
    def imagery
      if ENV["REAL_IMAGERY"]
        Imagery::Model.real { yield true }
      else
        Imagery::Model.fake { yield false }
      end
    end
  end
end
