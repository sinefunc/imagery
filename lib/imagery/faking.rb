module Imagery
  module Faking
    def self.included(base)
      base.extend ClassMethods
    end
      
    module ClassMethods
      def mode=(mode)
        @mode = mode
      end

      def mode
        @mode
      end

      def faked
        @omode, @mode = @mode, :fake
        yield
      ensure
        @mode = @omode
      end
    end

    def save(io)
      return true if self.class.mode == :fake

      super
    end
  end
end
