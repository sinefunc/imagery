module Imagery
  class Model 
    UnknownSize = Class.new(StandardError)

    attr :key
    attr :namespace
    attr :default
    attr :directory

    attr_writer   :root, :sizes
    
    def initialize(model, key = model.id, namespace = model.class.name.split('::').last.downcase)
      @key       = key.to_s
      @namespace = namespace
      @default   = { :original => ["1920x1200>"] }
      @directory = 'public/system'
      @sizes     = {}
    end
    
    def sizes
      @sizes.merge(@default)
    end
    
    def file(size = :original)
      raise UnknownSize, "#{ size } is not defined" unless sizes.has_key?(size)

      root_path(directory, namespace, key, filename(size))
    end

    def tmp
      root_path(directory, namespace, key, 'tmp')
    end

    def url(size = :original)
      file(size).split('public').last
    end
    
    module Persistence
      def save(io)
        FileUtils.mkdir_p(File.dirname(tmp))
        File.open(tmp, "wb") { |target| target.write(io.read) }
        sizes.keys.each { |size| convert(size) }
        FileUtils.rm(tmp)
        
        return true
      end

      def delete
        FileUtils.rm_rf File.dirname(file)
        return true
      end
    end
    include Persistence

  private
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
      @root
    end
   
    def root_path(*args)
      File.join(root, *args)
    end
  end
end
