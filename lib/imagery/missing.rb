module Imagery
  module Missing
    # Allows you to set the current filename of your photo.
    # Much of Imagery::Missing is hinged on this.
    #
    # @example
    #
    #   Photo = Class.new(Struct.new(:id))
    #   i = Imagery::Model.new(Photo.new(1001))
    #   i.extend Imagery::Missing
    #   i.url == "/photo/1001/original.png"
    #   # => true
    #
    #   i.existing = "Filename"
    #   i.url == "/missing/photo/original.png"
    #   # => true
    #
    # @see Imagery::Missing#url
    #
    attr_accessor :existing

    def url(size = self.default_size)
      if existing.to_s.empty?
        return ['', 'missing', namespace, filename(size)].join('/')
      else
        super
      end
    end
  end
end
