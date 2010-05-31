module Imagery
  module Missing
    def missing=(missing)
      @missing = missing
    end

    def missing
      @missing
    end

    def url(size = self.default_size)
      if missing 
        return ['', 'missing', namespace, filename(size)].join('/')
      else
        super
      end
    end
  end
end
