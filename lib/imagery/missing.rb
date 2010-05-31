module Imagery
  module Missing
    def existing=(existing)
      @existing = existing
    end

    def existing
      @existing
    end

    def url(size = self.default_size)
      if existing.to_s.empty?
        return ['', 'missing', namespace, filename(size)].join('/')
      else
        super
      end
    end
  end
end
