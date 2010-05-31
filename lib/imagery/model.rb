module Imagery
  class Model 
    UnknownSize   = Class.new(StandardError)
    UndefinedRoot = Class.new(StandardError)
  
    @@directory = 'public/system'
    @@default   = { :original => ["1920x1200>"] }

    # This is typically the database ID, you may also use something 
    # like a GUID for it, the sky's the limit.
    attr :key
  
    # Used as a grouping scheme, if you name this as `photos` for example,
    # you will have public/system/photos as the path.
    attr :namespace
  
    # Returns a single key => value pair hash, defaulting to @@default.
    attr :default

    # Returns the directory used which defaults to public/system.
    attr :directory
    
    # Defaulting to :original, the value used here will be the default 
    # size used when calling Imagery::Model#url and Imagery::Model#file.
    attr_accessor :default_size

    # Allows you to define the root of your application, all other paths
    # are determined relative to this.
    attr_writer :root

    # Allows you to define the different sizes you want as a hash of 
    # :style => [geometry] pairs.
    attr_writer :sizes
    
    # @param [#id] model any ruby object
    # @param [#to_s] key typically the database ID of a model. But you may also 
    #                use anything here just as long as its unique across the
    #                namespace.
    # @param [String] namespace used as a grouping mechanism for your images.
    def initialize(model, key = model.id, namespace = namespace_for(model.class))
      @key          = key.to_s
      @namespace    = namespace
      @default      = @@default
      @directory    = @@directory
      @sizes        = {}
      @default_size = :original
    end
    
    # Returns all the sizes defined including the default size.
    #
    # @example
    #   Photo = Class.new(Struct.new(:id))
    #   i = Imagery::Model.new(Photo.new(1001))
    #   i.sizes == { :original => ["1920x1280"] }
    #   # => true
    #
    #   i.sizes = { :thumb => ["48x48"] }
    #   i.sizes == { :thumb => ["48x48"], :original => ["1920x1280"] }
    #   # => true
    #
    # @return [Hash] size => [dimension] pairs.
    def sizes
      @sizes.merge(default)
    end
    
    # Gives the absolute file for a specified size.
    #
    # @example
    #
    #   Photo = Class.new(Struct.new(:id))
    #   i = Imagery.new(Photo.new(1001))
    #   i.root = '/tmp'
    #   i.file(:original) == '/tmp/public/system/photo/1001/original.png
    #   # => true
    #
    #   i.file(:thumb)
    #   # raise Imagery::Model::UnknownSize
    #
    #   i.sizes = { :thumb => ["100x100"] }
    #   i.file(:thumb) == '/tmp/public/system/photo/1001/thumb.png
    #   # => true
    #
    # @param [Symbol] size the size specific filename.
    # @raise [UnknownSize] if the size is not found in 
    #                      Imagery::Model#sizes.
    # @return [String] the absolute path of the size specific filename e.g.
    #                  /u/apps/reddit/current/public/system/photo/1/thumb.png
    #                  where photo is the namespace and 1 is the key.
    def file(size = self.default_size)
      raise UnknownSize, "#{ size } is not defined" unless sizes.has_key?(size)

      root_path(directory, namespace, key, filename(size))
    end
 
    # The Web module is basically here to let plugins override
    # the url as they see fit.
    #
    # @example
    #   module FunkyUrls
    #     def url(size = default_size)
    #       super.gsub('/system', '/funky')
    #     end
    #   end
    #
    #   class Imagery::Model
    #     include FunkyUrls
    #   end
    module Web
      # Gives the absolute URI path for use in a web context.
      #
      #   Photo = Class.new(Struct.new(:id))
      #   i = Imagery.new(Photo.new(1001))
      #   i.url(:original) == '/system/photo/1001/original.png
      #   # => true
      #
      #   i.file(:thumb)
      #   # raise Imagery::Model::UnknownSize
      #
      #   i.sizes = { :thumb => ["100x100"] }
      #   i.file(:thumb) == '/system/photo/1001/thumb.png
      #   # => true
      #
      # @param [Symbol] size the size specific url.
      # @raise [UnknownSize] if the size is not found in 
      #                      Imagery::Model#sizes.
      # @return [String] the absolute URI path of the size specific url e.g.
      #                  /system/photo/1/thumb.png
      #                  where photo is the namespace and 1 is the key.
      def url(size = self.default_size)
        file(size).split('public').last
      end
    end
    include Web
      
    # This module is basically here so that plugins like Imagery::S3
    # can override #save and #delete and call super.
    module Persistence
      # Writes the data in `io` and resizes them according to the different
      # geometry strings.
      #
      # @example
      #
      #   Photo = Class.new(Struct.new(:id))
      #   i = Imagery.new(Photo.new(1001))
      #   i.root = '/tmp'
      #   i.size = { :thumb => ["48x48"] }
      #   i.save(File.open('/path/to/file.jpg'))
      #
      #   File.exist?("/tmp/public/system/photo/1001/thumb.png")
      #   # => true
      #
      #   File.exist?("/tmp/public/system/photo/1001/original.png")
      #   # => true
      #
      # @param [#read] io any object responding to read. Typically
      #                a Rack filehandle is passed here from a 
      #                controller in rails or a Sinatra handler.
      #                You may also use File.open to provide a proper
      #                IO handle.
      # @return [true] returns when all other file operations are done.
      def save(io)
        FileUtils.mkdir_p(File.dirname(tmp))
        File.open(tmp, "wb") { |target| target.write(io.read) }
        sizes.keys.each { |size| convert(size) }
        FileUtils.rm(tmp)
        
        return true
      end
      
      # Deletes all of the files related to this Imagery::Model instance.
      # @return [true] when successfully deleted.
      def delete
        FileUtils.rm_rf File.dirname(file)
        return true
      end
    end
    include Persistence

  private
    def tmp
      root_path(directory, namespace, key, 'tmp')
    end

    def namespace_for(klass)
      klass.name.split('::').last.downcase
    end

    def filename(size)
      "%s.png" % size
    end
    
    def convert(size, geometry = self.sizes[size][0], extent = self.sizes[size][1])
      `#{ cmd size }`    
    end

    def cmd(size, geometry = self.sizes[size][0], extent = self.sizes[size][1])
      cmd = [].tap do |cmd|
        cmd.push 'convert', tmp
        cmd.push '-thumbnail', geometry
        cmd.push '-gravity', 'center'
        cmd.push '-extent', extent  if extent
        cmd.push file(size)
      end

      Escape.shell_command(cmd)
    end
    
    def root(root = defined?(ROOT_DIR) && ROOT_DIR)
      @root ||= root if root
      @root || raise(UndefinedRoot, "You must define Imagery::Model#root or have a ROOT_DIR constant present")
    end
   
    def root_path(*args)
      File.join(root, *args)
    end
  
    # Let's just assume everybody wants this functionality
    include Missing
  end
end
